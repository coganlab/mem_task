library(readxl)
library(stringr)
library(tidyverse)
library(jsonlite)
####
select_lures <- function(input_string, char_vector) {
  filtered_vector <- char_vector[char_vector != input_string]
    if(length(filtered_vector) < 2) {
    stop("Not enough different strings in the character vector.")
  }
    sampled_strings <- sample(filtered_vector, 2)
  return(sampled_strings)
}



####
gen_directory = 'C:/Users/Richy/Desktop/Memieeg'
stim_directory = file.path(gen_directory,'stimuli')
setwd(stim_directory)
n_subjects <- 10

#### Loop

for (sub_idx in 1:n_subjects) {
  
 object_list <- read.csv('object_list.csv')
 object_list <- object_list$ï..concept
 object_list <- gsub(" ", "_", object_list)
 
 face_list <- list.files(file.path(stim_directory,'faces'))
 face_list <- face_list[!grepl("1", face_list)]
 face_list <- face_list[!grepl('Adolf Hitler.png',face_list)]
 face_list <- gsub(".png", "", face_list)
 
 n_practice <- 5
 n_practice_l <- 3
 
 n_blocks <- 6
 n_trials <- 14
 n_lures <- 4
 
 practice_select <- c(3,11,20,50,70)
 practice_face <- face_list[practice_select]
 practice_ob <- object_list[1:(n_practice_l + n_practice)]
 
 face_list <- face_list[-practice_select]
 face_list <- sample(face_list)
 
 object_list <- object_list[(n_practice +  n_practice_l + 1):length(object_list)]
 object_list <- object_list[1:(length(face_list) +  n_lures*n_blocks)]
 object_list <- sample(object_list)
 
 white_lims <- c(0.5,0.75) 
 
 encoding_trials <- n_trials
 retrieval_trials <- n_trials + n_lures
 
 ## practice
 
 practice_encoding <- matrix(0L,nrow = n_practice, ncol = 5)
 practice_encoding <- as.data.frame(practice_encoding)
 colnames(practice_encoding) <- c('object','target','lure1','lure2','baseline')
 
 practice_lures <- matrix(0L,nrow = n_practice_l, ncol = 5)
 practice_lures <- as.data.frame(practice_lures)
 colnames(practice_lures) <- c('object','target','lure1','lure2','baseline')
 practice_lures$object <- practice_ob[(n_practice+1):length(practice_ob)]
 
 for (row_idx in 1:n_practice){
  
  object = practice_ob[row_idx] 
  target = practice_face[row_idx]
  cur_lures = select_lures(target,practice_face)
  baseline = round(runif(1, min = white_lims[1], max = white_lims[2]),2)
  
  practice_encoding$object[row_idx] <- object
  practice_encoding$target[row_idx] <- target
  practice_encoding$lure1[row_idx] <- cur_lures[1]
  practice_encoding$lure2[row_idx] <- cur_lures[2]
  practice_encoding$baseline[row_idx] <- baseline
  
 }
 
 for (lure_idx in 1:n_practice_l){
  
  target = practice_face[sample(1:length(practice_face),1)]
  cur_lures = select_lures(target,practice_face)
  baseline = round(runif(1, min = white_lims[1], max = white_lims[2]),2)
  
  practice_lures$target[lure_idx] <- target
  practice_lures$lure1[lure_idx] <- cur_lures[1]
  practice_lures$lure2[lure_idx] <- cur_lures[2]
  practice_lures$baseline[lure_idx] <- baseline
  
 }
 
 practice_retrieval <- practice_encoding
 
 practice_encoding$trial_type <- rep('Encoding',nrow(practice_encoding))
 practice_encoding$retrieval_type <- rep('Encoding',nrow(practice_encoding))
 
 practice_retrieval$trial_type <- rep('Retrieval',nrow(practice_retrieval))
 practice_retrieval$retrieval_type <- rep('Retrieval',nrow(practice_retrieval))
 practice_lures$trial_type <- rep('Retrieval',nrow(practice_lures))
 practice_lures$retrieval_type <- rep('Lure',nrow(practice_lures))
 
 practice_retrieval <- rbind(practice_retrieval,practice_lures)
 practice_retrieval <- practice_retrieval[sample(nrow(practice_retrieval)),]
 practice_block <- rbind(practice_encoding,practice_retrieval)
 
 
  if (sub_idx < 10) {
    cur_sub <- paste('S0',as.character(sub_idx),sep='')
  } else {
    cur_sub <- paste('S',as.character(sub_idx),sep='')
  }
  
  
  sub_folder <- file.path(gen_directory,'data','sub_lists',cur_sub)
  if (!dir.exists(sub_folder)) {
    dir.create(sub_folder)
  } 
  
  file_name <- paste(cur_sub,'_00.csv',sep="")
  file_name <- file.path(sub_folder,file_name)
  write.csv(practice_block,file_name,row.names = F)    
  
  
  for (block_idx in 1:n_blocks){
    
    block_faces <- face_list[1:n_trials]
    
    if (block_idx < n_blocks){
      face_list <-face_list[(n_trials + 1):length(face_list)]
    }
    
    block_objects <- object_list[1:retrieval_trials]
    
    if (block_idx < n_blocks){
      object_list <-object_list[(retrieval_trials + 1):length(object_list)]  
    }
    
    encoding <- matrix(0L,nrow = encoding_trials, ncol = 5)
    encoding <- as.data.frame(encoding)
    colnames(encoding) <- c('object','target','lure1','lure2','baseline')
    
    lures <- matrix(0L,nrow = n_lures, ncol = 5)
    lures <- as.data.frame(lures)
    colnames(lures) <- c('object','target','lure1','lure2','baseline')
    lures$object <- block_objects[(encoding_trials+1):length(block_objects)]
    
    for (row_idx in 1:encoding_trials){
      
      object = block_objects[row_idx] 
      target = block_faces[row_idx]
      cur_lures = select_lures(target,block_faces)
      baseline = round(runif(1, min = white_lims[1], max = white_lims[2]),2)
      
      encoding$object[row_idx] <- object
      encoding$target[row_idx] <- target
      encoding$lure1[row_idx] <- cur_lures[1]
      encoding$lure2[row_idx] <- cur_lures[2]
      encoding$baseline[row_idx] <- baseline
      
    }
    
    for (lure_idx in 1:n_lures){
      
      target = block_faces[sample(1:length(block_faces),1)]
      cur_lures = select_lures(target,block_faces)
      baseline = round(runif(1, min = white_lims[1], max = white_lims[2]),2)
      
      lures$target[lure_idx] <- target
      lures$lure1[lure_idx] <- cur_lures[1]
      lures$lure2[lure_idx] <- cur_lures[2]
      lures$baseline[lure_idx] <- baseline
      
    }
    
    lures$retrieval_type <- rep('Lure',nrow(lures))
    
    
    half_trials <- n_trials/2
    half_lures <- n_lures/2
    
    retrieval <- encoding   
    retrieval$retrieval_type <- rep('Retrieval',nrow(retrieval))
    
    retrieval_first <- retrieval[1:half_trials,]
    lures_first <- lures[1:half_lures,]
    retrieval_first <- rbind(retrieval_first,lures_first)
    retrieval_first <- retrieval_first[sample(1:nrow(retrieval_first)),]
    
    retrieval_second <- retrieval[(half_trials +1):nrow(retrieval),]
    lures_second <- lures[(half_lures +1):nrow(lures),]
    retrieval_second <- rbind(retrieval_second,lures_second)
    retrieval_second <- retrieval_second[sample(1:nrow(retrieval_second)),]
    retrieval <- rbind(retrieval_first,retrieval_second)
    retrieval$trial_type <- rep('Retrieval',nrow(retrieval))
    
    encoding$trial_type <- rep('Encoding',nrow(encoding))
    encoding$retrieval_type <- rep('Encoding',nrow(encoding))
    
    block <- rbind(encoding,retrieval)
    file_name <- paste(cur_sub,'_0', as.character(block_idx),'.csv',sep="")
    file_name <- file.path(sub_folder,file_name)
    write.csv(block,file_name,row.names = F)    
    
  }
  

  
  
}












