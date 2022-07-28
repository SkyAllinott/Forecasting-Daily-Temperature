# Load data:
setwd("G:/My Drive/R Projects/Daily Weather Data/")
data <- read.csv("weather_data.csv")
datasubset <- data[data$Station.Name == "EDMONTON BLATCHFORD",]
datasubset <- data.frame(date = as.Date(datasubset$Date), y = datasubset$Mean.Temperature..C.)
datasubset <- datasubset[order(datasubset$date),]

# Look for missing values:
# time series isn't matching up, so check for missing values:
date_range <- data.frame(date = seq(min(datasubset$date), max(datasubset$date), by=1))
date_range$date[!date_range$date %in% datasubset$date]

# There are some missing values, so I will left merge date_range on datasubset:
data.full <- merge(x = date_range, y = datasubset, by = 'date', all.x=TRUE)


# Splitting into test and train:
forecast.horizon <- 180
train <- data.full[1:(length(data.full$date)-forecast.horizon),]
test <- data.full[(length(data.full$date)-forecast.horizon+1):length(data.full$date),]


write.csv(train, "./train.csv")
write.csv(test, "./test.csv")
