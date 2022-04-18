# Modified after Allen & Bundenberg 2020

# Prerequisites -----------------------------------------------------------

#install.packages("tidyverse")
library(tidyverse)
#install.packages("sjlabelled")
library(sjlabelled) # for data manipulation
#install.packages("ggpubr")
library(ggpubr) # for box plots
#install.packages("rstatix")
library(rstatix) # for statistics
#install.packages("car")
library(car) #for anova (aov) function
#install.packages("RColorBrewer")
library(RColorBrewer) # for colour palettes


# Data Loader -------------------------------------------------------------

# setting data directory
data_path <- here("data", "habituation/") #specify directory of zantiks habituation files

#create list of files from directory
file_list <- list.files(data_path)

#create header from first file
df <-
  paste0(data_path, file_list[1]) %>%
  read_csv(skip=4,col_names = TRUE, guess_max = 100) %>%
  head(0)

#create new list without demographic info
new_list<- c()

for (i in file_list){
  new_list[[i]] <-
    read_csv(paste0(data_path, i),
             skip=4, col_names = TRUE, guess_max = 100) %>%
    head(-1)
}

#append all files to df
for (i in new_list){
  df<-add_row(df,i)
}

# Data Formatting ---------------------------------------------------------

#convert variables to factors for anova
df<-as_factor(df,BLOCK)
df<-as_factor(df,TYPE)
df<-as_factor(df,TIMESLOT)
df<-as_factor(df,UNIT)

#create file with total population columns
pop_data<-mutate(df,TOTAL_DIST = rowSums(select(df,!ends_with("MSD"), -RUNTIME,
                                                -UNIT, -TIMESLOT, -PLATE_ID,
                                                -TEMPERATURE, -TIME_BIN, -BLOCK,
                                                -TRIAL, -TYPE, -PRE_POST_COUNTER,
                                                -STARTLE_NUMBER)))
pop_data<-mutate(pop_data,TOTAL_ACT = rowSums(select(df,ends_with("MSD"))))

#create file with well factor and distance dv
dfile_dist<-
  df %>% 
  select(!ends_with("MSD")) %>%
  gather(key = "WELL", value = "DISTANCE", -RUNTIME, -UNIT, -TIMESLOT, -PLATE_ID,
         -TEMPERATURE, -TIME_BIN, -BLOCK, -TRIAL, -TYPE, -PRE_POST_COUNTER,
         -STARTLE_NUMBER) %>%
  convert_as_factor(WELL)

#create file with well factor and MSD activity dv only
dfile_act<-
  df %>% 
  select(ends_with("MSD")) %>%
  gather(key = "WELL", value = "ACTIVITY") %>%
  convert_as_factor(WELL)

#remove duplicate well variable before adding activity data
dfile_act<-select(dfile_act, -'WELL')

#add activity column to rest of data
df<-
  add_column(dfile_dist, dfile_act)

#remove acclimation data
no_acclimation<-
  df %>%
  filter(!(TYPE == "ACCLIMATION"))

#create data file with only startles
startles_only<-filter(df,TYPE=="STARTLE")
pop_startles_only<-filter(pop_data,TYPE=="STARTLE")


# Descriptive Statistics ---------------------------------------------------

#population data averaged across blocks
pop_startles_block<-
  pop_startles_only %>%
  group_by(STARTLE_NUMBER) %>%
  get_summary_stats(TOTAL_DIST, type = "mean_sd")


# Identify flies --------------

startles_only <- startles_only %>%
  mutate(fly_id = paste0(PLATE_ID, "_", WELL), fly_id_block = paste0(PLATE_ID, "_", WELL, "_", BLOCK)) %>%
  group_by(fly_id_block)

startles_only_act <- startles_only %>%
  filter(sum(DISTANCE) != 0) %>%
  ungroup()

overall_summary <- startles_only_act %>%
  group_by(STARTLE_NUMBER) %>%
  get_summary_stats(DISTANCE, type = "mean_sd")


# Remove flies that did not move at all -------------------




# Graphs ------------------------------------------------------------------

#pop habituation averaged across blocks graph
gg_pop_hab_block<-ggplot(data=pop_startles_block, aes(x = STARTLE_NUMBER, y = mean,)) +
  xlab("Trial") +
  ylab("Average Population Distance Travelled (pixels)") +
  geom_errorbar(aes(ymin=mean-(sd/sqrt(2)), ymax=mean+(sd/sqrt(2))), width=1, color = "grey44") +
  geom_line() +
  geom_point() + theme_classic() + theme(text = element_text(size = 15))
gg_pop_hab_block

#pop habituation by block graph
gg_pop_habituation<-ggplot(data=pop_startles_only, aes(x = STARTLE_NUMBER, y = TOTAL_DIST, group = BLOCK)) +
  geom_line()+
  geom_point(aes(shape=BLOCK)) + theme_classic()
gg_pop_habituation

#habituation data by individual
gg_habituation<-ggplot(data=startles_only, aes(x = STARTLE_NUMBER, y = DISTANCE, col = BLOCK)) +
  facet_wrap(startles_only$WELL) +
  geom_line() +
  geom_point()
gg_habituation


#habituation data by individual - only active flies
gg_habituation<-ggplot(data=startles_only_act, aes(x = STARTLE_NUMBER, y = DISTANCE, col = BLOCK)) +
  facet_wrap(facets = ~ fly_id) +
  geom_line() +
  geom_point() + theme_classic()
gg_habituation

#pop habituation averaged across blocks graph
gg_pop_all<-ggplot(data=overall_summary, aes(x = STARTLE_NUMBER, y = mean)) +
  xlab("Trial") +
  ylab("Average Population Distance Travelled (pixels)") +
  geom_errorbar(aes(ymin=mean-(sd/sqrt(2)), ymax=mean+(sd/sqrt(2))), width=1, color = "grey44") +
  geom_line() +
  geom_point() + theme_classic()
gg_pop_all
