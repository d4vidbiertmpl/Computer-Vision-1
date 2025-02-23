function net = update_model(no_epochs, batch_size, varargin)
opts.networkType = 'simplenn' ;
opts = vl_argparse(opts, varargin) ;

%% TODO: PLAY WITH THESE PARAMETERTS TO GET A BETTER ACCURACY

lr_prev_layers = [.2, 2];
lr_new_layers  = [1, 4]; 

lr = lr_prev_layers ;

% Meta parameters
net.meta.inputSize = [32 32 3];

% Divide epochs on learning rate: 2/5 for 0.05 and 0.005, 1/5 for 0.0005
no_epochs_40 = int32(no_epochs*0.4);
no_epochs_30 = int32(no_epochs*0.3);
no_epochs_25 = int32(no_epochs*0.25);
no_epochs_20 = int32(no_epochs*0.2);
no_epochs_10 = int32(no_epochs*0.1);
net.meta.trainOpts.learningRate = [ 0.05*ones(1, no_epochs_30) ...
                                    0.005*ones(1,no_epochs_25)...
                                    0.0005*ones(1, no_epochs_25)...
                                    0.0001*ones(1, no_epochs_20)...
                                    ];
                                
net.meta.trainOpts.weightDecay = 0.0001 ;
net.meta.trainOpts.batchSize = batch_size ;
net.meta.trainOpts.numEpochs = numel(net.meta.trainOpts.learningRate);

%% Define network 
net.layers = {} ;

% Block 1
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{0.01*randn(5,5,3,32, 'single'), zeros(1, 32, 'single')}}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 2) ;
net.layers{end+1} = struct('type', 'pool', ...
                           'method', 'max', ...
                           'pool', [3 3], ...
                           'stride', 2, ...
                           'pad', [0 1 0 1]) ;
net.layers{end+1} = struct('type', 'relu') ;

% Block 2
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{0.05*randn(5,5,32,32, 'single'), zeros(1,32,'single')}}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 2) ;
net.layers{end+1} = struct('type', 'relu') ;
net.layers{end+1} = struct('type', 'pool', ...
                           'method', 'avg', ...
                           'pool', [3 3], ...
                           'stride', 2, ...
                           'pad', [0 1 0 1]) ; % Emulate caffe

% Block 3
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{0.05*randn(5,5,32,64, 'single'), zeros(1,64,'single')}}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 2) ;
net.layers{end+1} = struct('type', 'relu') ;
net.layers{end+1} = struct('type', 'pool', ...
                           'method', 'avg', ...
                           'pool', [3 3], ...
                           'stride', 2, ...
                           'pad', [0 1 0 1]) ; % Emulate caffe

% Block 4
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{0.05*randn(4,4,64,64, 'single'), zeros(1,64,'single')}}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu') ;

%% TODO: Define the structure here, so that the network outputs 5-class rather than 10 (as in the pretrained network)
% Block 5

NEW_INPUT_SIZE  = 64;
NEW_OUTPUT_SIZE = 5;

net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{0.05*randn(1,1,NEW_INPUT_SIZE,NEW_OUTPUT_SIZE, 'single'), zeros(1,NEW_OUTPUT_SIZE,'single')}}, ...
                           'learningRate', .1*lr_new_layers, ...
                           'stride', 1, ...
                           'pad', 0) ;
                       

%%  Define loss                     
% Loss layer
net.layers{end+1} = struct('type', 'softmaxloss') ;

% Fill in default values
net = vl_simplenn_tidy(net) ;

oldnet = load('./data/pre_trained_model.mat'); oldnet = oldnet.net;
net = update_weights(oldnet, net);
end

%% Assign previous weights to the network
function newnet = update_weights(oldnet, newnet)

% loop until loss layer
for i = 1:numel(oldnet.layers)-2
    
    if(isfield(oldnet.layers{i}, 'weights'))
       
        newnet.layers{i}.weights = oldnet.layers{i}.weights;
        
    end
    
end

end

