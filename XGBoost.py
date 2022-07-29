import pandas as pd
import numpy as np
import xgboost as xgb
import matplotlib.pyplot as plt
from sklearn.experimental import enable_halving_search_cv
from sklearn.model_selection import HalvingRandomSearchCV
import os
import time
import random

os.chdir("G:/My Drive/R Projects/Daily Weather Data")

train = pd.read_csv('./Data/train.csv')
test = pd.read_csv('./Data/test.csv')
# Saving date index for plotting test set forecast afterwards
date = test['date']

# I have to create time series features for xgboost:
fulldata = train.append(test, ignore_index=True)
fulldata = fulldata[['y', 'date']]
fulldata['index'] = fulldata.index
fulldata['date'] = pd.to_datetime(fulldata['date'])
fulldata['dayofyear'] = fulldata['date'].dt.dayofyear
fulldata['dayofmonth'] = fulldata['date'].dt.day
fulldata['quarter'] = fulldata['date'].dt.quarter
fulldata['month'] = fulldata['date'].dt.month
fulldata['year'] = fulldata['date'].dt.year
fulldata['dayofweek'] = fulldata['date'].dt.dayofweek
fulldata['weekofyear'] = fulldata['date'].dt.weekofyear
fulldata = fulldata.drop('date', axis=1)
# XGBoost wasn't playing nice with NA's, so I'll interprolate with a linear method, as I did in nnetar
fulldata = fulldata.interpolate()



# Split data again:
train = fulldata.loc[0:(8243-181)]
test = fulldata.loc[8063:8243]
train_labels = train['y']
test_labels = test['y']
train_features = train.drop('y', axis=1)
test_features = test.drop('y', axis=1)
X, y = train_features, train_labels

# Parameter space:
# This was adjusted over several iterations. For a first coarse pass, I ran HalvingRandomSearch on wide parameter
# ranges for its speed to understand what the data liked. Once I understand where the model performed best,
# I restricted it to this HalvingGridSearch.
params = {'max_depth': [2, 4, 6, 8, 12],
          'learning_rate': [0.01, 0.03, 0.05],
          'subsample': np.arange(0.5, 0.7, 0.1),
          'colsample_bytree': np.arange(0.5, 0.8, 0.1),
          'n_estimators': np.arange(400, 1000, 100),
          'min_child_weight': [1, 2],
          'reg_alpha': [0, 1]}

# Tuning hyper parameters:
boost = xgb.XGBRegressor(seed=9)
clf = HalvingRandomSearchCV(estimator=boost,
                            param_distributions=params,
                            scoring='neg_mean_absolute_error',
                            n_jobs=-1,
                            verbose=1,
                            n_candidates=1000)


start = time.time()
clf.fit(X, y)
print("Best parameters: ", clf.best_params_)
print("Lowest MAE: ", (-clf.best_score_))
end = time.time()
print((end-start)/60)

# Exploring the results of the search:
# (used to update the next grid and get an idea of what works)
cv_results = pd.DataFrame(clf.cv_results_)
cv_results = cv_results.sort_values(by='rank_test_score')

# Fitting the optimal model from the search:
best_parameters = clf.best_params_
boost_best = xgb.XGBRegressor(seed=9, **best_parameters)
boost_best.fit(train_features, train_labels)

xgb.plot_importance(boost_best)
plt.subplots_adjust(left=.2)

predictions = boost_best.predict(test_features)
errors_boost = abs(predictions - test_labels)
MAE = round(np.mean(errors_boost), 2)
print(MAE)
errors_boost_perc = abs((test_labels-predictions)/test_labels)
MAPE = round(np.mean(errors_boost_perc), 2)*100
print(MAPE)

plt.plot(test['index'], test['y'], color='black')
plt.plot(test['index'], predictions, color='red')

# Get prediction intervals:
iterations = 100
prediction_set = np.zeros(shape=(180, iterations))
for i in range(iterations):
    model = xgb.XGBRegressor(seed=(i*random.randint(1,100)), **best_parameters)
    model.fit(train_features, train_labels)
    prediction_set[:, i] = model.predict(test_features)

prediction_set_test = prediction_set.transpose()

standard_deviations = np.std(prediction_set_test, axis=0)

date = pd.to_datetime(date)
fig, ax = plt.subplots()
plt.plot(date, test['y'], color='black', label="Actual Value")
plt.plot(date, predictions, color='steelblue', label="Forecasted Value")
plt.fill_between(date, (predictions-2*standard_deviations), (predictions+2*standard_deviations), color='lightblue', alpha=0.6, label="95% Prediction Interval")
plt.legend(loc='upper left')
plt.title("XGBoost Forecast of Daily Temperature in Edmonton")
plt.xlabel("Date (Year-Month)")
plt.ylabel("Temperature (Celsius)")
