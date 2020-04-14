source('./narr_data_functions.R')

d <- d <- readRDS('/Users/RASV5G/OneDrive - cchmc/CF_local_data/d_narr_cells.rds') %>%
  mutate(VisitDate = as.Date(VisitDate, format = '%m/%d/%y'), 
         start_date = VisitDate - lubridate::days(7), 
         end_date = VisitDate) %>% 
  rename(narr_cell_number = narr_cell)
  

get_narr_data(d, narr_variables = c('air.2m', 'rhum.2m'))
