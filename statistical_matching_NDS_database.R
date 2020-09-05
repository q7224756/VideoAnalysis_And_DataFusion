# R-Paket laden

library(StatMatch)
library(dplyr)
library(catdap)
library(mipfp)
library(writexl)
library(readxl)
library(proxy)
library(RANN)
library(PerformanceAnalytics)


# Harmonisieren

ordner.R      <- "F:/DAK_2019-16_Zian_Yin/05. R Code für Datenbankfusion/"
Spender       <- read_excel(paste(ordner.R, "Videodatenbank_Sid.xlsx", sep = ""))
Empfaenger    <- read_excel(paste(ordner.R, "FSD_Sid.xlsx",sep = ""))
Spender       <- as.data.frame(Spender) # Formatkonvertierung (erforderlicher Schritt)
Empfaenger    <- as.data.frame(Empfaenger)

Empfaenger$c1.vFZMeanTimeWindow <- cut(Empfaenger$vFZMeanTimeWindow,breaks = 1*(0:22)) # Kategorisierung von der Geschwindigkeit von Empfaengerdatenbank
K1   <- levels(factor(Empfaenger$Maneuver))              # K1 ist die Klasse der Maneuver von Empfaenger
K2   <- Spender$Maneuver                                 # K2 ist die Klasse der Maneuver von Spender
K3   <- levels(factor(Empfaenger$c1.vFZMeanTimeWindow))  # K3 ist die Klasse der kategorisierten Geschwindigkeit von Empfaenger
K4   <- Spender[which(K2 %in% K1),]                      # K4 ist Spenderdatenbank, die gleiche Klasse der Maneuver mit Empfaenger hat.
K4$c1.vFZMeanTimeWindow  <- cut(K4$vFZMeanTimeWindow,breaks = 1*(0:26)) #K5 ist die Klasse der Geschwindigkeit von Spender
K5 <- K4[which(K4$c1.vFZMeanTimeWindow %in% K3),]
write_xlsx(K5[1:6], paste(ordner.R,"Videodatenbank_Sid_Neu.xlsx", sep = ""))
Spender       <- read_excel(paste(ordner.R, "Videodatenbank_Sid_Neu.xlsx", sep = ""))
Empfaenger    <- read_excel(paste(ordner.R, "FSD_Sid.xlsx",sep = ""))
Spender       <- as.data.frame(Spender)
Empfaenger    <- as.data.frame(Empfaenger)
Spender$c.TrafficDensity        <- cut(Spender$TrafficDensity, breaks = 45*(0:10))
Spender$c.vFZMeanTimeWindow     <- cut(Spender$vFZMeanTimeWindow,breaks = 4.4*(0:5))
Spender$c.HasStopped            <- as.factor(Spender$HasStopped)
Spender$c.Maneuver              <- as.factor(Spender$Maneuver)
Spender$c.Day                   <- as.factor(Spender$Day)
Spender$c.Timezone              <- as.factor(Spender$Timezone)
Empfaenger$c.vFZMeanTimeWindow  <- cut(Empfaenger$vFZMeanTimeWindow,breaks = 4.4*(0:5))
Empfaenger$c.HasStopped         <- as.factor(Empfaenger$HasStopped)
Empfaenger$c.Maneuver           <- as.factor(Empfaenger$Maneuver)
Empfaenger$c.Day                <- as.factor(Empfaenger$Day)
Empfaenger$c.Timezone           <- as.factor(Empfaenger$Timezone)
str(Spender)
str(Empfaenger)
assoc       <- pw.assoc(c.TrafficDensity~c.vFZMeanTimeWindow+c.HasStopped+c.Day+c.Maneuver+c.Timezone, data = Spender,out.df = TRUE)
sort        <- assoc[order(-assoc$U),]
print(sort)
Matching <- c("vFZMeanTimeWindow")

method      <- RANDwNND.hotdeck(data.rec = Empfaenger, data.don = Spender, match.vars = Matching, don.class = c("c.vFZMeanTimeWindow","c.HasStopped","c.Maneuver"), cut.don = "span", k=0.1, dist.fun = "Manhattan", keep.t = TRUE)
print(method)
spezivar    <- c("TrafficDensity","c.TrafficDensity")
Ergebnis    <- create.fused(data.rec = Empfaenger, data.don = Spender, mtc.ids = method$mtc.ids, z.vars = spezivar)

chart.Correlation(Ergebnis[c("TrafficDensity","vFZMeanTimeWindow")], histogram=TRUE)

Level                 <- levels(factor(Ergebnis$c.TrafficDensity))
Level.Spender         <- Spender[which(Spender$c.TrafficDensity%in%Level),] # Werte in Spender herausfiltern, die mit gleicher Kategorien (Level) von fusionierte Empfaenger sind
tt.Spender            <- xtabs(~c.TrafficDensity, data=Level.Spender)
tt.Ergebnis           <- xtabs(~c.TrafficDensity, data=Ergebnis)
Randverteilung        <- comp.prop(p1=tt.Ergebnis, p2=tt.Spender, n1=nrow(Ergebnis),n2=NULL,ref=TRUE)
Randverteilung$meas
tt.Spender                          <- xtabs(~c.TrafficDensity+c.vFZMeanTimeWindow, data=Level.Spender)
tt.Ergebnis                         <- xtabs(~c.TrafficDensity+c.vFZMeanTimeWindow, data=Ergebnis)
Verteilung.vDichte.vFZ              <- comp.prop(p1=tt.Ergebnis, p2=tt.Spender, n1=nrow(Ergebnis),n2=NULL,ref=TRUE)
Verteilung.vDichte.vFZ$meas
tt.Spender                          <- xtabs(~c.TrafficDensity+c.Maneuver, data=Level.Spender)
tt.Ergebnis                         <- xtabs(~c.TrafficDensity+c.Maneuver, data=Ergebnis)
Verteilung.vDichte.Maneuver         <- comp.prop(p1=tt.Ergebnis, p2=tt.Spender, n1=nrow(Ergebnis),n2=NULL,ref=TRUE)
Verteilung.vDichte.Maneuver$meas
chart.Correlation(Ergebnis[c("TrafficDensity","vFZMeanTimeWindow")], histogram=TRUE)

assoc       <- pw.assoc(c.TrafficDensity~c.vFZMeanTimeWindow+c.HasStopped+c.Day+c.Maneuver+c.Timezone, data = Ergebnis,out.df = TRUE)
sort        <- assoc[order(-assoc$U),]
print(sort)


write_xlsx(Ergebnis, paste(ordner.R,"Synt_Sid.xlsx", sep = ""))
