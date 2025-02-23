function [net, info, expdir] = finetune_cnn(no_epochs, batch_size, id, varargin)

%% Define options
run(fullfile(fileparts(mfilename('fullpath')), ...
  'MatConvNet', 'matlab', 'vl_setupnn.m')) ;

opts.modelType = 'lenet' ;
[opts, varargin] = vl_argparse(opts, varargin) ;

opts.expDir = fullfile('data', ...
  sprintf('cnn_assignment-%s', opts.modelType)) ;
[opts, varargin] = vl_argparse(opts, varargin) ;

opts.expDir = opts.expDir + id;

disp("AFTER CONCAT")
disp(opts.expDir)

opts.dataDir = './data/' ;
opts.imdbPath = fullfile(opts.expDir, 'imdb-stl.mat');
opts.whitenData = true ;
opts.contrastNormalization = true ;
opts.networkType = 'simplenn' ;
opts.train = struct() ;
opts = vl_argparse(opts, varargin) ;
if ~isfield(opts.train, 'gpus'), opts.train.gpus = []; end;
opts.train.gpus = [];



%% update model

net = update_model(no_epochs, batch_size);

%% TODO: Implement getIMDB function below

if exist(opts.imdbPath, 'file')
  imdb = load(opts.imdbPath) ;
else
  imdb = getIMDB() ;
  mkdir(opts.expDir) ;
  save(opts.imdbPath, '-struct', 'imdb') ;
end

%%
net.meta.classes.name = imdb.meta.classes(:)' ;

% -------------------------------------------------------------------------
%                                                                     Train
% -------------------------------------------------------------------------

trainfn = @cnn_train ;
[net, info] = trainfn(net, imdb, getBatch(opts), ...
  'expDir', opts.expDir, ...
  net.meta.trainOpts, ...
  opts.train, ...
  'val', find(imdb.images.set == 2)) ;

expdir = opts.expDir;
end
% -------------------------------------------------------------------------
function fn = getBatch(opts)
% -------------------------------------------------------------------------
switch lower(opts.networkType)
  case 'simplenn'
    fn = @(x,y) getSimpleNNBatch(x,y) ;
  case 'dagnn'
    bopts = struct('numGpus', numel(opts.train.gpus)) ;
    fn = @(x,y) getDagNNBatch(bopts,x,y) ;
end

end

function [images, labels] = getSimpleNNBatch(imdb, batch)
% -------------------------------------------------------------------------
images = imdb.images.data(:,:,:,batch) ;
labels = imdb.images.labels(1,batch) ;
if rand > 0.5, images=fliplr(images) ; end

end

% -------------------------------------------------------------------------
function imdb = getIMDB()
% -------------------------------------------------------------------------
% Preapre the imdb structure, returns image data with mean image subtracted
classes = {'airplane', 'bird', 'ship', 'horse', 'car'};
splits = {'train', 'test'};

disp("Create new data")

%% TODO: Implement your loop here, to create the data structure described in the assignment
%% Use train.mat and test.mat we provided from STL-10 to fill in necessary data members for training below
%% You will need to, in a loop function,  1) read the image, 2) resize the image to (32,32,3), 3) read the label of that image

train_path = '../stl10_matlab/train.mat';
test_path = '../stl10_matlab/test.mat';
addpath('../Project_Part1/')

[X_train, y_train, train_class_idx] = load_data(train_path, classes);
[X_test, y_test, test_class_idx] = load_data(test_path, classes);

data = zeros(32, 32, 3, 0, 'single');
for i = 1:size(X_train, 1)
    obervation = X_train(i, :);
    im_rgb = reshape(obervation, 96, 96, 3);
    im_rez = imresize(im_rgb, [32, 32]);
    im_sin = im2single(im_rez);
    data = cat(4, data, im_sin);
end
for i = 1:size(X_test, 1)
    obervation = X_test(i, :);
    im_rgb = reshape(obervation, 96, 96, 3);
    im_rez = imresize(im_rgb, [32, 32]);
    im_sin = im2single(im_rez);
    data = cat(4, data, im_sin);
end

%data = single(data);
disp("Data shape")
disp(size(data))

labels = cat(1, y_train, y_test);
% Restructure labels => ships:3; horses: 4; car: 5 
labels(labels == 7) = 4;
labels(labels == 3) = 5;
labels(labels == 9) = 3;
labels = transpose(labels);

set_train = ones(size(y_train));
set_test = ones(size(y_test)) * 2;
sets = cat(1, set_train, set_test);
sets = transpose(sets);

%%
% subtract mean
dataMean = mean(data(:, :, :, sets == 1), 4);
data = bsxfun(@minus, data, dataMean);

imdb.images.data = data ;
imdb.images.labels = single(labels) ;
imdb.images.set = sets;
imdb.meta.sets = {'train', 'val'} ;
imdb.meta.classes = classes;

perm = randperm(numel(imdb.images.labels));
imdb.images.data = imdb.images.data(:,:,:, perm);
imdb.images.labels = single(floor(imdb.images.labels(perm)));
imdb.images.set = single(imdb.images.set(perm));
end
