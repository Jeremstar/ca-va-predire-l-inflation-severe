library(ggplot2)
library(dplyr)
library(lubridate)
library(car)
library(stargazer)
library(survey)

OECD <- OECD_short_term_economic_indicators
IMF<- IMF_monetary_policy
Enq13<- FRBNY_SCE_Public_Microdata_Complete_13_16
Enq17 <- FRBNY_SCE_Public_Microdata_Complete_17_19
Enq20 <- frbny_sce_public_microdata_latest_1_

# Graphique d'indice des prix ? la consommation --------------------

inflation_US<-subset(OECD, OECD$Country=="United States" & OECD$Subject2=="Consumer prices: all items")
inflation_US2<-data.frame(
  day=as.Date(inflation_US$Time,format='%Y-%m-%d'),
  Inflation=as.numeric(inflation_US$Value)
)

plot(inflation_US2$day,inflation_US2$Inflation,,type='l',xlab='Date',ylab="Prix ? la consommation",col='royalblue3')

mean(Enq17$Q8v2part2, na.rm = TRUE)

#--------------- calcul du taux d'inflation -------------

inflation_US3 <-data.frame(
  date=inflation_US2$day,
  tx_evol_ann_pct = (inflation_US2$Inflation / lag(inflation_US2$Inflation,12) - 1) * 100)
  


# Conversion des formats nuls de time en date -------------

Enq17$date=ymd(paste(Enq17$date,'01',sep=''))
Enq13$date=ymd(paste(Enq13$date,'01',sep=''))
Enq20$date=ymd(paste(Enq20$date,'01',sep=''))

# ---------- Graphique des anticipations d'inflation ? court terme ---------------------

anticipation_short_pond=Enq_tot %>%                        
  group_by(date) %>%                        
  summarise_at(vars(Q8v2part2,weight),
               list(name = weighted.mean),na.rm = TRUE)




ggplot(anticipations_short) + geom_line(aes(x = date, y = name))+ylab('Expected inflation - 12 months')

# ---------- Graphique des anticipations d'inflation ? moyen terme ---------------------

anticipation_mid_pond=Enq_tot %>%                        
  group_by(date) %>%                        
  summarise_at(vars(Q9bv2part2,weight),
               list(name = weighted.mean),na.rm = TRUE)

anticipations_mid=rbind(anticipations_mid_13, anticipations_mid_17,anticipations_mid_20)


ggplot(anticipation_mid_pond) + geom_line(aes(x = date, y = Q9bv2part2_name))+ylab('Expected inflation - in 36 months')

# ---------- Cr?ation de bases de comparaison ---------------------

# ---------- Comparaison pour du court terme ----------------------

comp_infl_short<-data.frame(
  merge(inflation_US3,anticipations_short,by="date")
)

comp_infl_short$expected=lag(comp_infl_short$name,12)
comp_infl_short$dif=comp_infl_short$expected-comp_infl_short$tx_evol_ann_pct

ggplot(comp_infl_short) + geom_line(aes(x = date, y = anticipation_short_pond$Q8v2part2_name,colour='Expected'))+geom_line(aes(x = date, y = tx_evol_ann_pct,colour='Real'))+ylab('Inflation rate')+scale_color_manual(name = "Inflation", values = c("Real"='red', "Expected"='blue'))+scale_x_date(limits = c(as.Date('2014-05-01'),as.Date('2022-01-01')))+ggtitle('Comparaison inflation anticip?e ? m-12 et inflation r?alis?e')

# ---------- Comparaison pour du moyen terme ----------------------
comp_infl_mid<-data.frame(
  merge(inflation_US3,anticipations_mid,by="date")
)
comp_infl_mid$expected=lag(comp_infl_mid$name,36)
comp_infl_mid$dif=comp_infl_mid$expected-comp_infl_mid$tx_evol_ann_pct

ggplot(comp_infl_mid) + geom_line(aes(x = date, y = expected,colour='Expected'))+geom_line(aes(x = date, y = tx_evol_ann_pct,colour='Real'))+ylab('Inflation rate')+scale_color_manual(name = "Inflation", values = c("Real"='red', "Expected"='blue'))+scale_x_date(limits = c(as.Date('2016-05-01'),as.Date('2022-01-01')))+ggtitle('Comparaison inflation anticip?e ? m-36 et inflation r?alis?e')

# --------- On passe maintenant aux histograms pour ?tudier l'h?t?rog?n?it? des r?ponses"
# Court terme:
#cr?ation d'un dataframe pour regrouper toutes les r?ponses:


ggplot(anticipation_short_pond, aes(x=Q8v2part2_name)) + geom_histogram(binwidth = 1,col='grey')+coord_cartesian(xlim=c(-5,15))+scale_x_continuous(breaks = seq(-5,15,1), lim = c(-5,15))+xlab('Inflation antici?e 12 mois apr?s enqu?te')

#Long terme:


ggplot(rep_mid, aes(x=mid)) + geom_histogram(binwidth = 1,col='grey')+coord_cartesian(xlim=c(-5,15))+scale_x_continuous(breaks = seq(-5,15,1), lim = c(-5,15))+xlab('Inflation antici?e 12 mois apr?s enqu?te')

# Fusion des bases de donn?es ( utile pour faire des r?gressions ) :
Enq_tot_1<-rbind(Enq13,Enq17,Enq20)
Enq_tot<-filter(Enq_tot_1,abs(Q8v2part2)<100 & abs(Q9bv2part2)<100)

scatterplot(Q9bv2part2~Q8v2part2, data=Enq_tot)

reg1=lm(Q9bv2part2~Q8v2part2, data=Enq_tot)
summary(reg1)


# Formattage de donn?es pour faire des r?gressions :
test<-Enq_tot

# Ici, on s'occupe de regrouper toutes les infos sur les revenus en un vecteur :
test$income

for(i in 1:length(Enq_tot$userid)){
  if (is.na(test$D6[i])==FALSE)
  {test$income[i]=test$D6[i]}
  if (is.na(test$Q47[i])==FALSE)
  {test$income[i]=test$Q47[i]}
}

#C'est fait. Maintenant, on va cr?er des vecteurs binaires Low income et middle income pour reproduire l'analyse de Bellemare:
# On cr?e ici la variable low income: 0-50 000 $ par an : 
test$low_income

for(i in 1:length(test$userid)){
  if(is.na(test$income[i])){test$low_income[i]=NA} else{
  if (test$income[i]<=5)
  {test$low_income[i]<-1} else 
  {test$low_income[i]<-0}}
}
# On cr?e ici la variable middle income: 50-100 000 $ par an :
test$middle_income
for(i in 1:length(test$userid)){
  if(is.na(test$income[i])){test$middle_income[i]=NA} else{
    if (test$income[i]>=6 & test$income[i]<=8)
    {test$middle_income[i]<-1} else 
    {test$middle_income[i]<-0}}
}

# On s'occupe maintenant de l'?ducation:
for(i in 1:length(test$userid)){if(is.na(test$QNUM1[i])==FALSE){
  test$QNUM1[test$userid==test$userid[i]]<-test$QNUM1[i]
  test$QNUM2[test$userid==test$userid[i]]<-test$QNUM2[i]
  test$QNUM3[test$userid==test$userid[i]]<-test$QNUM3[i]
  test$QNUM4[test$userid==test$userid[i]]<-test$QNUM4[i]
  test$QNUM5[test$userid==test$userid[i]]<-test$QNUM5[i]
  test$QNUM6[test$userid==test$userid[i]]<-test$QNUM6[i]
  test$QNUM7[test$userid==test$userid[i]]<-test$QNUM7[i]
  test$QNUM8[test$userid==test$userid[i]]<-test$QNUM8[i]
  test$QNUM9[test$userid==test$userid[i]]<-test$QNUM9[i]
  
  
  
  
}}
# On cr?e ensuite deux vecteurs: un qui code le nombre de bonnes r?ponses, l'autre le nombre de r?ponses manquantes:
# En fait c'?tait inutile la variable est d?j? cod?e :)
test$empty_answers=c(0)
test$right_answers=c(0)
for(i in 1:length(test$userid)){
  if(is.na(test$QNUM1[i])==FALSE){
  if(test$QNUM1[i]==150){test$right_answer[i]=test$right_answer[i]+1}
}else{test$empty_answer[i]=test$empty_answer[i]+1}
  if(is.na(test$QNUM2[i])==FALSE){
    if(test$QNUM2[i]==242){test$right_answer[i]=test$right_answer[i]+1}
  }else{test$empty_answer[i]=test$empty_answer[i]+1}
  if(is.na(test$QNUM3[i])==FALSE){
    if(test$QNUM3[i]==10){test$right_answer[i]=test$right_answer[i]+1}
  }else{test$empty_answer[i]=test$empty_answer[i]+1}
  if(is.na(test$QNUM5[i])==FALSE){
    if(test$QNUM5[i]==100){test$right_answer[i]=test$right_answer[i]+1}
  }else{test$empty_answer[i]=test$empty_answer[i]+1}
  if(is.na(test$QNUM6[i])==FALSE){
    if(test$QNUM6[i]==5){test$right_answer[i]=test$right_answer[i]+1}
  }else{test$empty_answer[i]=test$empty_answer[i]+1}
  if(is.na(test$QNUM8[i])==FALSE){
    if(test$QNUM8[i]==2 | test$QNUM8[i]==TRUE){test$right_answer[i]=test$right_answer+1}
  }else{test$empty_answer[i]=test$empty_answer[i]+1}
  if(is.na(test$QNUM9[i])==FALSE){
    if(test$QNUM9[i]==2 | test$QNUM9[i]==FALSE){test$right_answer[i]=test$right_answer+1}
  }else{test$empty_answer[i]=test$empty_answer[i]+1}
}

# Ici on va se servir de la variable d?j? cod? pour cr?er une variable binaire:
names(test)[names(test) == "_NUM_CAT"] <- "NUM_CAT"

for(i in 1:length(test$userid)){
  if(is.na(test$NUM_CAT[i])){test$low_numeracy[i]=NA} else{
    if (test$NUM_CAT[i]=='Low')
    {test$low_numeracy[i]<-1} else 
    {test$low_numeracy[i]<-0}}
}

#cr?ation de la variable young et middle age:
names(test)[names(test) == "_AGE_CAT"] <- "AGE_CAT"
test$young=c(0)
test$middle_age=c(0)
for(i in 1:length(test$userid)){
  if(is.na(test$AGE_CAT[i])){test$young[i]=NA
  test$middle_age[i]=NA} else{
    if (test$AGE_CAT[i]=='Under 40')
    {test$young[i]<-1} else 
    {test$young[i]<-0}
    if(test$AGE_CAT[i]=='40 to 60')
    {test$middle_age[i]<-1} else 
    {test$middle_age[i]<-0}}
}

#cr?ation des variables sur le niveau d'?tude: 
names(test)[names(test) == "_EDU_CAT"] <- "EDUC_CAT"
test$some_college=c(0)
test$high_school=c(0)
for(i in 1:length(test$userid)){
  if(is.na(test$EDUC_CAT[i])){test$some_college[i]=NA
  test$high_school[i]=NA} else{
    if (test$EDUC_CAT[i]=='High School')
    {test$high_school[i]<-1} else 
    {test$high_school[i]<-0}
    if(test$EDUC_CAT[i]=='Some College')
    {test$some_college[i]<-1} else 
    {test$some_college[i]<-0}}
}

#Cr?ation de la variable genre:
# on s'occupe de mettre des variables de genre pour toutes les r?ponses:
for(i in 1:length(test$userid)){if(is.na(test$Q33[i])==FALSE){
  test$Q33[test$userid==test$userid[i]]<-test$Q33[i]}}

# Maintenant on peut cr?er la variable:

test$female=c(0)
for(i in 1:length(test$userid)){
  if(is.na(test$Q33[i])){test$female[i]=NA
 } else{
    if (test$Q33[i]==2)
    {test$female[i]<-1} else 
    {test$female[i]<-0}
    }
}

# Maintenant on s'occupe de renseigner le taux d'inflation au moment de la r?ponse:
test$current_inflation=c(0)
for(i in 1:length(inflation_US3$date)){
  test$current_inflation[test$date==inflation_US3$date[i]]<-inflation_US3$tx_evol_ann_pct[i]}

regression_bellemare=lm(Q8v2part2~current_inflation+female+some_college+high_school+young+middle_age+low_income+middle_income,data = test,weights = test$weight)
summary(regression_bellemare)

stargazer(regression_bellemare)
Enq_tot<-test

# Maintenant, on va refaire des stats mais en prenant en compte la pond?ration :




