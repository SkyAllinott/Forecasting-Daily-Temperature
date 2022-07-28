library(forecast)
library(ggplot2)
library(doParallel)

setwd("G:/My Drive/R Projects/Daily Weather Data/")



data <- read.csv("weather_data.csv")
datasubset <- data[data$Station.Name == "EDMONTON BLATCHFORD",]
datasubset$Date <- as.Date(datasubset$Date)
datasubset <- datasubset[order(datasubset$Date),]

data.ts <- ts(datasubset$Mean.Temperature..C., start=c(2000, 1, 1), frequency=365)


# time series isn't matching up, so check for missing values:
date_range <- seq(min(datasubset$Date), max(datasubset$Date), by=1)
date_range[!date_range %in% datasubset$Date]


data.arima.train <- ts(data.ts[1:(length(data.ts)-180)], start=c(2000,1,1), frequency=365)
data.arima.test <- data.frame(y = data.ts[(length(data.ts)-179):length(data.ts)])


model <- auto.arima(data.arima.train, stepwise=TRUE, approximation = TRUE)
summary(model)

forecast <- forecast(model, h=180, level=95)
data.arima.test$yhat <- forecast$mean
data.arima.test$yhat_lower <- forecast$lower
data.arima.test$yhat_upper <- forecast$upper
data.arima.test$error <- data.arima.test$y-data.arima.test$yhat
data.arima.test$date <- seq(as.Date("2021-12-11"), as.Date("2022-6-8"), by=1)
mean(abs(data.arima.test$error))

colors <- c("True Values" = 'black', "Fitted Values" = "steelblue", 'Confidence Interval' = 'lightblue')
ggplot(data.arima.test, aes(x=date, group=1), alpha=1) +
  geom_line(aes(y=y, col='True Values'), size=1) +
  geom_line(aes(y = yhat, col='Fitted Values'), size=1) + 
  geom_ribbon(aes(ymin=yhat_lower, ymax=yhat_upper), fill='lightblue', alpha=0.4) +
  labs(x="Date",
       y="Mean Temperature (Celcius)") +
  ggtitle("SARIMA Forecast of Daily Temperature in Edmonton") +
  scale_color_manual(values = colors) +
  theme(legend.title=element_blank()) +
  theme(axis.line.x=element_line(color='black', size=0.75, linetype='solid'),
        axis.line.y=element_line(color='black', size=0.75, linetype='solid'),
        panel.background=element_rect('white', 'white', size=0.5),
        legend.key=element_rect(fill='transparent', color='transparent'))


