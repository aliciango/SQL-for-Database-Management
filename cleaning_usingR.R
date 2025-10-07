install.packages("dplyr")
library(dplyr)
# read csv file
hot100 <- read.csv("C:/Users/jingn/Documents/SQL/Billboard/hot100.csv")

# convert to the right data type before importing to sql
hot100$Date <- as.Date(hot100$Date, format = "%Y-%m-%d")   # character → Date
hot100$Last.Week <- as.integer(hot100$Last.Week)           # character → integer
hot100$Weeks.in.Charts <- as.integer(hot100$Weeks.in.Charts) # character → integer
hot100$Image.URL <- as.character(hot100$Image.URL)         # keep as character (URL)

# view the structure after changing
str(hot100)

# clean up null values
colSums(is.na(hot100))
## > last.week: two null values
## > weeks.in.Charts: 35 444 null values



######################
# remove two records that has last.week = NULL
hot100 <- hot100 %>% 
  filter(!is.na(Last.Week))

# replace NULL values with zero in weeks.in.Charts
hot100 <- hot100 %>% 
  mutate(Weeks.in.Charts = ifelse(is.na(Weeks.in.Charts), 0, Weeks.in.Charts))

# remove the last column
hot100 <- hot100 %>% 
  select(-last_col())

# remove duplicates
hot100 <- hot100 %>% 
  distinct(Date, Song, Artist, Rank, Last.Week, Peak.Position, Weeks.in.Charts, .keep_all = TRUE)


# examine a duplicated case, but after cleaning, there is no more duplicated value!
examine <- hot100 %>% 
  filter(Date == '1971-06-16')

######################
# export hot100 to CSV
write.csv(hot100, "C:/Users/jingn/Documents/SQL/Billboard/hot100_clean.csv", row.names = FALSE)



