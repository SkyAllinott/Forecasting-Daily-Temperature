# Forecasting Daily Temperature in Edmonton:
## Table of Contents
* [Overview](https://github.com/SkyAllinott/Forecasting-Daily-Temperature#overview)
  - [Understanding this repo](https://github.com/SkyAllinott/Forecasting-Daily-Temperature/edit/master/README.md#understanding-this-repo)

* [Results](https://github.com/SkyAllinott/Forecasting-Daily-Temperature#results)

  -  [MAPE as an accuracy measure](https://github.com/SkyAllinott/Forecasting-Daily-Temperature#mape-as-an-accuracy-measure)

* [Models](https://github.com/SkyAllinott/Forecasting-Daily-Temperature#model-discussion)
  -  [Prophet](https://github.com/SkyAllinott/Forecasting-Daily-Temperature#1-prophet)
  -  [XGBoost](https://github.com/SkyAllinott/Forecasting-Daily-Temperature#1-XGBoost)
  -  [NNETAR](https://github.com/SkyAllinott/Forecasting-Daily-Temperature#1-nnetar)
  -  [SARIMA](https://github.com/SkyAllinott/Forecasting-Daily-Temperature#1-sarima) 

* [Seasonality](https://github.com/SkyAllinott/Forecasting-Daily-Temperature#seasonality)

## Overview
Pulling data from Edmonton's Open data portal (https://data.edmonton.ca/Environmental-Services/Weather-Data-Daily-Environment-Canada/s4ws-tdws), I forecast daily weather using a training set of January 1st, 2000 to January 27, 2022. I then forecast from January 28th, 2022 to July 26, 2022 (180 days).

I use Facebook's Prophet model, a seasonal ARIMA model, a feed forward neural network (NNETAR), and an XGBoost model with derived time series features.

### Understanding this repo:
The main analytical files (where models are fitted and forecasted) is within the main page. I include figures in `./Figures`. These contain the forecasts seen below, and the seasonality discussion at the end.

The `./Data` folder contains the original .csv downloaded, the script to transform it, and the training and test data, should you want it.

## Results

|  Measure | Prophet | SARIMA | NNETAR | XGBoost |
| ----- | ------- | ------ | ---- | ---- |
| Mean Absolute Error (MAE) | 3.71 | 6.41 | 4.57 | 3.79 |
| Mean Absolute Percentage Error (MAPE) | 162.27 | 263.73 | 124.55 | 157.0 |

The lowest MAE comes from Facebook's Prophet model, and suggests the 180 day forecast is off by an average of 3.71 degrees, each day. 

The lowest MAPE is the NNETAR model; which has a higher MAE than the Prophet model.

### MAPE as an accuracy measure
This inconsistency is because the MAPE measure is **not symmetric**. In simple terms, the MAPE punishes x units above the actual value more than x units below. Due to this, if you used MAPE as an accuracy measure to fit models, then you would consistently get models that predict too low. You will see in the NNETAR forecast figure below that it is consistently under the true value for a portion of the model, which leads to it lowering it's MAPE, but keeping its higher MAE than prophet.

However, the MAPE is scale invariant, and so after the model is constructed, comparisons between MAPE's can be made. Importantly, since the MAPE isn't used in model construction, the odds of a forecast being too high/too low is more or less random, so MAPE remains a viable comparison; after forecasting. 

Typical wisdom suggests that forecasts with MAPE > 50 are "poor forecasters." Even the best model is several times larger than the accepted tolerance. Temperature however is known to be a tricky forecast, and these models can perform much better on different series. For instance, in my forecast of hourly energy consumption (repo available on my profile), the MAPE for the Prophet model was ~8, which typical wisdom denotes an "excellent" forecast. 

Due to better performance on other series, and the variety of methods used, I believe the high MAPE's reflect the difficulty of this series. 

## Model Discussion
I discuss the models in order of accuracy.

### 1. Prophet
![prophetforecast](https://user-images.githubusercontent.com/52394699/181845985-1f3fdca9-5d01-4c91-aace-a24b4a6c0441.png)

As you can see, Prophet does not try to do anything fancy to match the variations in data. In fact, it essentially looks like an HP filter was applied to the data, and has simply extracted the trend. While this is somewhat unsatisfying, if there is little information in the series (IE, past weather has relatively little impact on future weather on a systematic scale), then this is about the best you can do.

The Prophet model was the simplest to set up, and is estimated the fastest. One of the big selling points of Prophet is that it balances speed and accuracy; however I find there that it is both the most accurate and fastest. 

### 2. XGBoost
![xgboostforecastupdated](https://user-images.githubusercontent.com/52394699/181847024-8da9782d-78e9-4f80-a1d7-1848efc1373a.png)

Note that XGBoost is very similar to Prophet, but has a tiny bit more wiggle. I calculated the prediction interval by forecasting the model 100 times with a different seed, which leads to slight variation in forecasts. The interval is then taken to be $y \pm 2*SD$; where SD is the standard deviation of all 100 models on that date.

I forecasted using XGBoost by taking the date series and decomposing it to variables like "year", "day of year", "day of month", "index", "month", etc. This worked very well, and the feature importance (discussed later), can be used to see which seasonality level is the most important. I think this approach can be very useful in helping to identify seasonality levels in time series data. 



### 3. NNETAR
![nnetar forecast](https://user-images.githubusercontent.com/52394699/181846442-a4938beb-4f69-4d4c-aa43-5d05bc5c88e3.png)

The NNETAR model is third in terms of accuracy. It largely follows the trend like Prophet, but is more "wiggly." 

One issue with the NNETAR model is that due to NA's in the year before the test set, the model could not be fitted, so the temperatures had to be interprolated (I used a simple linear interprolation). On weather data, and at such a low frequency (<15 observations missing in ~8200 observations) this isn't a big deal, but is a downside to NNETAR. 

Another issue is that the model is HIGHLY volatile. Rerunning the code and estimating the model can lead to wildly different results. The reported errors from above are on the lower side of what I saw rerunning the model a few times. One way to combat this is to increase the `repeats` variable in NNETAR, which would estimate more models and average their forecast. This would decrease variance but significantly increase processing time, which was already quite high.

Finally, since the data does not follow a weekly or monthly seasonality, but more a yearly seasonality, NNETAR cannot use the first year of information in the series. Again, in such a long series this isn't important, but it is worth noting.

### 4. SARIMA
![ARIMA forecast](https://user-images.githubusercontent.com/52394699/181847445-9a3d99f1-8dd2-4758-b468-fc9aa30c0b62.png)

The SARIMA model is the most wiggly, and this is completely detrimental to the model. 

The SARIMA model is the worst by far, and suffers from many issues. Like NNETAR, it drops the first year of data. However it can deal with the NA's. 

However, the worst offence is it's computation time. Utilising just `auto.arima`, which selects the optimal model using in-sample fit, takes about 15 minutes to run; even with enhancements that sacrifice accuracy for speed. This makes it by far the slowest method, for the worst results.

## Seasonality
Here I utilise Prophet to understand the seasonality effects, using the figure below:
![prophet seasonality](https://user-images.githubusercontent.com/52394699/181847917-77d7412b-344d-4413-a2f4-7a3a53349479.png)

As you can see, there is a weak upwards trend across the sample (about .3 degrees from 2000 to 2020). By day of week, it appears thursday is the hottest day (about 0.1 degree above average). Finally, looking at day of the year, we can see the clear seasonal pattern of cold winters and hot summers; all looks as it should here. 

However, when it comes to these long-term trends and day of week seasonality, these are small values; are they even important or valid? Here I utilise XGBoost. XGBoost has both of these features available, and we can see how important each were to the model to understand the strength of these questionable seasonal patterns.

![xgboost feature importance updated](https://user-images.githubusercontent.com/52394699/181848099-663af9fd-31f0-4a14-a94e-4f0cd183e7a6.png)

The day of the year is the most important variable to XGBoost; suggesting clear support of annual seasonality. The index (long term trend), is also fairly strong, and lends validity to the impact of the long-term trend in Prophet's model. However, the day of week is the least important variable (as one may expect). This suggests that while Prophet picked up some variation, it is not important to the model and is likely to be a random result. 
