library(prophet)
library(ggplot2)

# Loading data:
setwd("G:/My Drive/R Projects/Daily Weather Data/Data/")
train <- read.csv("train.csv")
test <- read.csv("test.csv")


# Prophet requires specific naming convention for dataframe
train.prophet <- data.frame(ds = train$date, y = train$y)
test.prophet <- data.frame(ds=as.Date(test$date), y=test$y)


# Estimating model:
model <- prophet(train.prophet, seasonality.mode = 'additive', changepoint.prior.scale = 0.01)

# 180 period forecast, same as test set:
future <- make_future_dataframe(model, periods = 180, freq = 'day')
forecast <- predict(model, future)
test.prophet$yhat <- forecast$yhat[8064:8243]
test.prophet$yhat_lower <- forecast$yhat_lower[8064:8243]
test.prophet$yhat_upper <- forecast$yhat_upper[8064:8243]
test.prophet$error <- test.prophet$y-test.prophet$yhat
mean(abs(test.prophet$error), na.rm = TRUE)


# Plotting seasonality components:
prophet_plot_components(model, forecast)
# Plotting fit and forecast:
plot(model, forecast)


# Plotting forecast on test set for better visualization:
colors <- c("True Values" = 'black', "Fitted Values" = "steelblue", 'Confidence Interval' = 'lightblue')
ggplot(test.prophet, aes(x=ds, group=1), alpha=1) +
  geom_line(aes(y=y, col='True Values'), size=1) +
  geom_line(aes(y = yhat, col='Fitted Values'), size=1) + 
  geom_ribbon(aes(ymin=yhat_lower, ymax=yhat_upper), fill='lightblue', alpha=0.4) +
  labs(x="Date",
       y="Mean Temperature (Celcius)") +
  ggtitle("Prophet Forecast of Daily Temperature in Edmonton") +
  scale_color_manual(values = colors) +
  theme(legend.title=element_blank()) +
  theme(axis.line.x=element_line(color='black', size=0.75, linetype='solid'),
        axis.line.y=element_line(color='black', size=0.75, linetype='solid'),
        panel.background=element_rect('white', 'white', size=0.5),
        legend.key=element_rect(fill='transparent', color='transparent'))


# Visualising changepoints to see if I need to tune model:
plot(model, forecast) + add_changepoints_to_plot(model)
