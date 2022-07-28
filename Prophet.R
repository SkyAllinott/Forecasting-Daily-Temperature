library(prophet)
library(ggplot2)

setwd("G:/My Drive/R Projects/Daily Weather Data/")



data <- read.csv("weather_data.csv")
datasubset <- data[data$Station.Name == "EDMONTON BLATCHFORD",]

data.prophet <- data.frame(ds = datasubset$Date, y = datasubset$Mean.Temperature..C.)
data.prophet$ds <- as.Date(data.prophet$ds)

data.prophet <- data.prophet[order(data.prophet$ds),]
rownames(data.prophet) <- NULL


plot(data.prophet$ds, data.prophet$y, type='l')


# 30 day forecast:

data.prophet.train <- data.prophet[1:(length(data.prophet$ds)-180),]
data.prophet.test <- data.prophet[(length(data.prophet$ds)-179):length(data.prophet$ds),]


model <- prophet(data.prophet.train, seasonality.mode = 'multiplicative', changepoint.prior.scale = 0.5)
future <- make_future_dataframe(model, periods = 180, freq = 'day')
forecast <- predict(model, future)
data.prophet.test$yhat <- forecast$yhat[8010:8189]
data.prophet.test$yhat_lower <- forecast$yhat_lower[8010:8189]
data.prophet.test$yhat_upper <- forecast$yhat_upper[8010:8189]
data.prophet.test$error <- data.prophet.test$y-data.prophet.test$yhat
mean(abs(data.prophet.test$error))

prophet_plot_components(model, forecast)
plot(model, forecast)


# Only off by 2 degrees.
colors <- c("True Values" = 'black', "Fitted Values" = "steelblue", 'Confidence Interval' = 'lightblue')
ggplot(data.prophet.test, aes(x=ds, group=1), alpha=1) +
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


plot(model, forecast) + add_changepoints_to_plot(model)
