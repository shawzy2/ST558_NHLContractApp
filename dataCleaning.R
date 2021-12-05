##### Data cleaning/engineering #####
library(jsonlite)
library(tidyverse)
library(fastDummies)

# read data in
contracts <- fromJSON('data/contract_info.json')
player_info <- fromJSON('data/player_info.json')
skater_stats <- fromJSON('data/player_stats_skaters.json')

#### contracts cleaning ####
contracts$signingDate <- ifelse(substr(contracts$signingDate, start = 1, stop = 3)=='May',
                                paste0(substr(contracts$signingDate, start = 1 , stop = 3 ), '.', substr(contracts$signingDate, 4, 30)),
                                contracts$signingDate)
contracts$signingDate <- as.Date(contracts$signingDate, format = "%b. %d, %Y") # convert signingDate string to date
contracts$seasonId <- as.character(as.numeric(format(contracts$signingDate,'%Y'))-1)
contracts$length <- parse_number(str_split_fixed(contracts$length, ' ', 2)[,1]) # convert length of contract to numeric
contracts$totalValue <- parse_number(contracts$totalValue) # convert total contract value from string to numeric
contracts$capHitPercentage <- parse_number(contracts$capHitPercentage) / 100 # adjust capHitPercentage to be between 0 and 1
contracts <- contracts[, !(names(contracts) %in% c('signingTeam'))] # drop unnecessary cols

#### player info cleaning ####
player_info$born <- ifelse(substr(player_info$born, start = 1, stop = 3)=='May',
                           paste0(substr(player_info$born, start = 1 , stop = 3 ), '.', substr(player_info$born, 4, 30)),
                           player_info$born)
player_info$born <- as.Date(player_info$born, format = "%b. %d, %Y") # convert born string to date
player_info$height <- str_split_fixed(player_info$height, '"', 2)[,1]
player_info$height <- parse_number(str_split_fixed(player_info$height, "'", 2)[,1])*12 + 
  parse_number(str_split_fixed(player_info$height, "'", 2)[,2]) # convert height to inches
player_info$weight <- parse_number(str_split_fixed(player_info$weight, " lbs", 2)[,1]) # convert weight to lbs
player_info$position <- ifelse(grepl('Centre', player_info$position) & grepl('Wing', player_info$position),
                               'Centre, Wing',
                               ifelse(grepl('Defense', player_info$position),
                                      'Defense',
                                      ifelse(grepl('Left Wing', player_info$position) & grepl('Right Wing', player_info$position),
                                             'Left/Right Wing',
                                             player_info$position))
) # consolidate the number of positions seen in dataset
player_info$draftRound <- ifelse(player_info$draftRound=='-', '10', player_info$draftRound) # fill in 'undrafted' values
player_info$draftOverall <- parse_number(ifelse(player_info$draftOverall=='-', '301', player_info$draftOverall)) # fill in 'undrafted' values
player_info <- player_info[c('link', 'position', 'born', 'nationality', 'height', 'weight', 'handness', 'draftYear', 'draftOverall', 'draftRound')] # trim unnecessary cols

#### skater stats cleaning ####
skater_stats <- skater_stats %>% filter(league == 'NHL')
skater_stats <- skater_stats[, !(names(skater_stats) %in% c('team', 'league'))] # drop unnecessary cols
skater_stats[(skater_stats == '-') | (skater_stats == '')] <- '0'   # replace missing values
skater_stats$toi <- ifelse(skater_stats$toi == '0', 
                           0,
                           parse_number(str_split_fixed(skater_stats$toi, ":", 2)[,1])*60 + 
                             parse_number(str_split_fixed(skater_stats$toi, ":", 2)[,2])) # convert time-on-ice to seconds
skater_stats$playoff_toi <- ifelse(skater_stats$playoff_toi == '0', 
                                   0,
                                   parse_number(str_split_fixed(skater_stats$playoff_toi, ":", 2)[,1])*60 + 
                                     parse_number(str_split_fixed(skater_stats$playoff_toi, ":", 2)[,2])) # convert time-on-ice to seconds
skater_stats[,3:28] <- sapply(skater_stats[,3:28], as.numeric) # convert to numeric cols
skater_stats$seasonId <- substr(skater_stats$season, start=1, stop=4)
skater_stats <- skater_stats %>%
  group_by(link, season, seasonId) %>%
  summarize_all(sum) # group together players that have multiple obs for a single season (happens when player is traded mid-season)
# get lagged data (previous year's performance, second most previous year's performance)
lag1 <- skater_stats %>% 
  group_by(link) %>% 
  mutate_at(vars(-link, -season, -seasonId), lag) %>%
  rename_at(vars(-link, -season, -seasonId), ~ paste0("prev1_", .x))

lag2 <- lag1 %>% 
  group_by(link) %>% 
  mutate_at(vars(-link, -season, -seasonId), lag) %>%
  rename_at(vars(-link, -season, -seasonId), ~ paste0("prev2_", substr(.x, start = 7, stop = 40)))
# merge with lagged observations
skater_stats <- merge(skater_stats, lag1, c('link', 'seasonId', 'season'))
skater_stats <- merge(skater_stats, lag2, c('link', 'seasonId', 'season'))
skater_stats[is.na(skater_stats)] <- 0 # fill na's with 0

# merge data
df <- merge(contracts, player_info, by = 'link')
df_skaters <- df %>% filter(position != 'Goaltender')
#df_goalies <- df %>% filter(position == 'Goaltender')
df_skaters <- left_join(df_skaters, skater_stats, by = c('link', 'seasonId'))
df_skaters <- df_skaters %>% filter(!is.na(df_skaters$signingDate))
df_skaters[is.na(df_skaters)] <- 0 # fill na's with 0

# add age at signing feature
df_skaters$ageAtSigningInDays <- df_skaters$signingDate - df_skaters$born

# remove unnessary columns
df_skaters <- df_skaters %>% select(-c(signingDate, born, nationality, draftYear, season))

# save df to drive
write.csv(df_skaters,'data/skater_contracts_stats_eda.csv', row.names = FALSE)

# create dummyvars
dcols <- c('type', 'expiraryStatus', 'position', 'handness', 'draftRound')
df_skaters <- dummy_cols(df_skaters, select_columns = dcols, remove_selected_columns = TRUE)

# convert seasonId to numeric
df_skaters$seasonId <- as.numeric(df_skaters$seasonId)

# save df to drive
write.csv(df_skaters,'data/skater_contracts_stats.csv', row.names = FALSE)
