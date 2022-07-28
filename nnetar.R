library(forecast)
library(ggplot2)
library(dplyr)
library(zoo)
library(generics)


# Load data:
setwd("G:/My Drive/R Projects/Daily Weather Data/Data/")
train <- read.csv("train.csv")
test <- read.csv("test.csv")


# frequency 365.25 to deal with leap years:
# This daily frequency will make arima estimation take a long time.
# However this is necessary as there is no theoretical weekly frequency.
train.ts <- ts(train$y, start=c(2000, 1), frequency=365.25)

# Since seasonality is 365, any NA's in the last year of data causes an error in nnetar
# I will approximate these by just connecting a smooth path between the data as these 
# NA's are minimal, but this is suboptimal.
train <- train %>%
  mutate(y = na.approx(y))

# Redo ts class
train.ts <- ts(train$y, start=c(2000, 1), frequency=365.25)
plot(train.ts)


# Fit model:
model <- nnetar(train.ts)
summary(model)

# Predict, with prediction intervals:
forecast <- forecast::forecast(model, h=180, level=95, PI=TRUE)
test$yhat <- forecast$mean
test$yhat_lower <- forecast$lower
test$yhat_upper <- forecast$upper

# MAE:
test$error <- test$y-test$yhat
mean(abs(test$error), na.rm=TRUE)

# MAPE:
test$errorperc <- abs((test$y-test$yhat)/test$y)
mean(test$errorperc, na.rm = TRUE)*100

colors <- c("True Values" = 'black', "Fitted Values" = "steelblue", 'Confidence Interval' = 'lightblue')
ggplot(test, aes(x=as.Date(date), group=1), alpha=1) +
  geom_line(aes(y=y, col='True Values'), size=1) +
  geom_line(aes(y = yhat, col='Fitted Values'), size=1) + 
  geom_ribbon(aes(ymin=yhat_lower, ymax=yhat_upper), fill='lightblue', alpha=0.4) +
  labs(x="Date",
       y="Mean Temperature (Celcius)") +
  ggtitle("NNETAR Forecast of Daily Temperature in Edmonton") +
  scale_color_manual(values = colors) +
  theme(legend.title=element_blank()) +
  theme(axis.line.x=element_line(color='black', size=0.75, linetype='solid'),
        axis.line.y=element_line(color='black', size=0.75, linetype='solid'),
        panel.background=element_rect('white', 'white', size=0.5),
        legend.key=element_rect(fill='transparent', color='transparent'))
