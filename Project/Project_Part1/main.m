clc
clear all
close all

run vlfeat/toolbox/vl_setup

train_path = 'stl10_matlab/train.mat';
test_path = 'stl10_matlab/test.mat';
res_path = 'res/';
log_path = 'log.txt';

classes_used = {'airplane', 'bird', 'car', 'horse', 'ship'};

% PARAMS TO TRY OUT:
num_clusters     =  [400,1000,2000,4000];   
sift_types       =  ["regular", "dense"];
img_types        =  ["gray", "rgb", "opponent"]; 


vocab_ratio = 0.3333; % percentage of training data used for building visual vocab

% Currently no usage of the following param, we use all images for training.
% has to be in [50, floor((2500/5)*(1-vocab_ratio))]
% i.e. in our case it has to be in [50, 333]
svm_train_data_ratio = 0.5; % max: 1


% Logging
logfile_id = fopen(log_path,'a');
fprintf(logfile_id, '----------- RESULTS OF CV1 ASSIGNMENT -----------\n\n');
fprintf(logfile_id,'vocab_ratio: ');
fprintf(logfile_id, num2str(vocab_ratio));
fprintf(logfile_id,'\nsvm_train_data_ratio: ');
fprintf(logfile_id,num2str(svm_train_data_ratio));

% Load data.
disp('Load data.')
[X_train, y_train, class_idx] = load_data(train_path,classes_used);
[X_test, y_test, ~] = load_data(test_path,classes_used);

%%%%% START FOR LOOPS %%%%%%
for u=1:size(num_clusters,2)
num_cluster = num_clusters(u);
for uu=1:size(sift_types,2)
sift_type = sift_types(uu);
for uuu=1:size(img_types,2)
img_type = img_types(uuu);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%       

% Filename for saving outputs.
run_description = img_type+"_"+sift_type+"_"+num2str(num_cluster)+"_";
run_path = res_path+run_description;

% Start logging
fprintf(logfile_id,'\n\n-------');
fprintf(logfile_id, run_description);
fprintf(logfile_id,'-------\n');
disp('---------- NEW RUN ----------')
disp(run_description)
disp('-----------------------------')

% Divide training data in two parts: One is used for building the visual
% vocabulary, the other is transformed into histograms of visual words.
disp('Divide training data.')
[X_train_vocab, X_train_hist, y_train_hist] = divide_training_data(X_train,...
                                                                   y_train,...
                                                                   class_idx,...
                                                                   vocab_ratio);

% Build visual vocabulary. (Tasks 2.1 and 2.2)
disp('Build visual vocabulary.')
[cluster_centers] =  build_visual_vocab(X_train_vocab,...  
                                        num_cluster,...
                                        img_type,...
                                        sift_type);
                              
% Respresent remaining training data points as collections (=histograms) of
% visual words from the isual vocabulary. (Tasks 2.3 and 2.4)
disp('Build histograms from train images.')
X_hists =  images_to_histograms(X_train_hist,...
                                cluster_centers,...
                                img_type,...
                                sift_type);                   
                            
% Train 5 binary SVMs (Task 2.5)
disp('Training SVMs')
svms = train_svms(X_hists,...
                  y_train_hist,...
                  svm_train_data_ratio,...
                  class_idx);

              
% Evaluate System (Task 2.6)
% Calculate histograms for test images with global visual words
disp('Evaluation:')
disp('    - Build histograms from test images.')
test_hists  =  images_to_histograms(X_test,...
                                    cluster_centers,...
                                    img_type,...
                                    sift_type);
                               
% Perform Evaluation
disp('    - Perform evaluation.')
[m_av_prec, av_prec, m_acc, acc] =  evaluation(X_test,...
                                               test_hists,...
                                               y_test,...
                                               svms,...
                                               class_idx,...
                                               run_path);

 % Log results                             
 fprintf(logfile_id,"\n MAP: ");
 fprintf(logfile_id,num2str(m_av_prec));
 fprintf(logfile_id,"\n");
 for i=1:size(classes_used,2)
    fprintf(logfile_id,  num2str(av_prec(i)));
    fprintf(logfile_id, " ");
 end
 
 fprintf(logfile_id,"\n");
  fprintf(logfile_id,"\n ACC: ");
 fprintf(logfile_id,num2str(m_acc));
 fprintf(logfile_id,"\n");
 for i=1:size(classes_used,2)
    fprintf(logfile_id,  num2str(acc(i)));
    fprintf(logfile_id, " ");
 end
 fprintf(logfile_id,"\n");
 
 
%%%%% END FOR LOOPS %%%%%%
end
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
 
fclose(logfile_id);
 
 
 
 