function [RAND_FOREST,LINEAR_SVM] = FN_VTTBoW( DATA,DATA_GROUP,DATA_TAGS,USE_LINEAR_SVM,USE_RANDOM_FOREST,Param_GLCM,WORDS,SUBSET_SIZE )
global RANDOM_FOREST_VERBOSE;
global RANDOM_FOREST_TREES;
global RANDOM_FOREST_VERBOSE_MODEL;
global LINEAR_SVM_VERBOSE;

if isempty(LINEAR_SVM_VERBOSE)
    LINEAR_SVM_VERBOSE = false;
end

if isempty(RANDOM_FOREST_VERBOSE_MODEL)
    RANDOM_FOREST_VERBOSE_MODEL = false;
end

if isempty(RANDOM_FOREST_VERBOSE)
    RANDOM_FOREST_VERBOSE = false;
end

if isempty(RANDOM_FOREST_TREES)
    RANDOM_FOREST_TREES = 50;
end


RandomForest_Confusion            = cell(1,1);
RandomForest_Accuracy             = zeros(1,1);
RandomForest_Probablity_estimates = cell(1,1);
RandomForest_Training_model       = cell(1,1);
RandomForest_Final_decision       = cell(1,1);
RandomForest_Actual_answer        = cell(1,1);
RandomForest_Vocabulary        = cell(1,1);

LinearSVM_Confusion            = cell(1,1);
LinearSVM_Accuracy             = zeros(1,1);
LinearSVM_Probablity_estimates = cell(1,1);
LinearSVM_Training_model       = cell(1,1);
LinearSVM_Final_decision       = cell(1,1);
LinearSVM_Actual_answer        = cell(1,1);
LinearSVM_Vocabulary        = cell(1,1);

[G GN] = grp2idx(DATA_TAGS);  % Reduce character tags to numeric grouping

WORDSET = [10,50,100,400,800,1000];
SVMBest = 0;
SVMWords = 100;
RFBest  =0;
RFWords = 100;
BestWords = 100;

for k = 1: length(WORDSET)
    
    WORDS = WORDSET(k);
    disp(['Starting Test ',num2str(k)]);
    
    testData = strfind(DATA_GROUP,'Validation');
    testData= find(~cellfun(@isempty,testData));
    TESTIDX = false(length(DATA_GROUP),1);
    TESTIDX(testData) = true;

    trainData =  strfind(DATA_GROUP,'Training');
    trainData = find(~cellfun(@isempty,trainData));
    TRAINIDX = false(length(DATA_GROUP),1);
    TRAINIDX(trainData) = true;
    
    %validationData =  strfind(DATA_GROUP,'Validation');
    %validationData = find(~cellfun(@isempty,validationData));
    %TRAINIDX = false(length(DATA_GROUP),1);
    %TRAINIDX(validationData) = true;
    
    
   
    
    %Generate Vocobulary from Training Data
    
    UnFormattedData = FN_ReformalizeDescriptorFromStructure( DATA, Param_GLCM.pyramid,8 );
    TRAINData = FN_ReformalizeDescriptorFromStructure( DATA(TRAINIDX,:), Param_GLCM.pyramid,8 );
    TRAINData = cell2mat(TRAINData);
    % Pick a subset
    if SUBSET_SIZE <= length(TRAINData)
        SubsetInd = randperm(length(TRAINData));
        SubsetInd = SubsetInd(1:SUBSET_SIZE);
    else
        SubsetInd = 1:length(TRAINData);
    end
    
    if length(SubsetInd) < WORDS
        VOCAB = ML_VocabGeneration( TRAINData(SubsetInd,:), length(SubsetInd) );
    else
        VOCAB = ML_VocabGeneration( TRAINData(SubsetInd,:), WORDS );   
    end
    
    clear TRAINData;
    
    
    REFORMALIZEDDATA = ML_NearestWord( UnFormattedData, VOCAB,WORDS );

    % Reformalulate back into a Structure
   % DATA = FN_ReformalizeDescriptorToStructure( WordRepresentation, Param_GLCM.pyramid,WORDS );

    
    
    if USE_LINEAR_SVM
    %% TEST USING LINEAR SVM

        LinearSVM_Vocabulary{k} = VOCAB;
        
        if length(GN) > 2
                [ LinearSVM_Confusion{k},...
            LinearSVM_Accuracy(k),...
            LinearSVM_Probablity_estimates{k},...
            LinearSVM_Training_model{k},...
            LinearSVM_Final_decision{k},...
            LinearSVM_Actual_answer{k} ]...
            = ML_MultiClassLibLinearSVM(REFORMALIZEDDATA ,TESTIDX,TRAINIDX,G,GN,LINEAR_SVM_VERBOSE );
        else
                [ LinearSVM_Confusion{k},...
            LinearSVM_Accuracy(k),...
            LinearSVM_Probablity_estimates{k},...
            LinearSVM_Training_model{k},...
            LinearSVM_Final_decision{k},...
            LinearSVM_Actual_answer{k} ]...
            = ML_TwoClassLibLinearSVM(REFORMALIZEDDATA ,TESTIDX,TRAINIDX,G,GN,LINEAR_SVM_VERBOSE );
        end
        
        
        LINEAR_SVM{1}   =   LinearSVM_Confusion;
        LINEAR_SVM{2}   =   LinearSVM_Accuracy;
        LINEAR_SVM{3}   =   LinearSVM_Probablity_estimates;
        LINEAR_SVM{4}   =   LinearSVM_Training_model;
        LINEAR_SVM{5}   =   LinearSVM_Final_decision;
        LINEAR_SVM{6}   =   LinearSVM_Actual_answer;
        LINEAR_SVM{7}   =   GN;
        LINEAR_SVM{8}   =   LinearSVM_Vocabulary;
        
        [ ~,~,~,SVMCurrent ] = FN_MultiConf( LINEAR_SVM );
        disp(['LinearSVM',num2str(SVMCurrent)]);
        if SVMCurrent > SVMBest
            SVMBest = SVMCurrent;
            SVMWords = WORDS;
            BestWords = WORDS;
        end
        
    end
    
    if USE_RANDOM_FOREST
    %% TEST RANDOM FOREST
    [RandomForest_Confusion{k},...
        RandomForest_Accuracy(k),...
        RandomForest_Probablity_estimates{k},...
        RandomForest_Training_model{k},...
        RandomForest_Final_decision{k},...
        RandomForest_Actual_answer{k} ] = ML_TwoClassForest(REFORMALIZEDDATA,...
        TESTIDX,...
        TRAINIDX,...
        G,...
        GN,...
        RANDOM_FOREST_TREES,...
        RANDOM_FOREST_VERBOSE,...
        RANDOM_FOREST_VERBOSE_MODEL);
        RandomForest_Vocabulary{k} = VOCAB;
    
        
        RAND_FOREST{1}  =   RandomForest_Confusion;
        RAND_FOREST{2}  =   RandomForest_Accuracy;
        RAND_FOREST{3}  =   RandomForest_Probablity_estimates;
        RAND_FOREST{4}  =   RandomForest_Training_model;
        RAND_FOREST{5}  =   RandomForest_Final_decision;
        RAND_FOREST{6}  =   RandomForest_Actual_answer;
        RAND_FOREST{7}  =   GN;
        RAND_FOREST{8}  =   RandomForest_Vocabulary;

        [ ~,~,~,RFCurrent ] = FN_MultiConf( RAND_FOREST );
        disp(['Random Forest',num2str(RFCurrent)]);
        if RFCurrent > RFBest
            RFBest = RFCurrent;
            RFWords = WORDS;
            BestWords = WORDS;
        end
    end
    
    
end

%% Perform the final test
disp('Loading Test Data');

    
    WORDS = WORDSET(k);
    disp(['Starting Test ',num2str(k)]);
    
  
    testData = strfind(DATA_GROUP,'Testing');
    testData= find(~cellfun(@isempty,testData));
    TESTIDX = false(length(DATA_GROUP),1);
    TESTIDX(testData) = true;

    trainData =  strfind(DATA_GROUP,'Training');
    trainData = find(~cellfun(@isempty,trainData));
    TRAINIDX = false(length(DATA_GROUP),1);
    TRAINIDX(trainData) = true;
    
        validationData =  strfind(DATA_GROUP,'Validation');
    validationData = find(~cellfun(@isempty,validationData));
    TRAINIDX = false(length(DATA_GROUP),1);
    TRAINIDX(validationData) = true;
    
    
    
    %Generate Vocobulary from Training Data
    
    UnFormattedData = FN_ReformalizeDescriptorFromStructure( DATA, Param_GLCM.pyramid,8 );
    TRAINData = FN_ReformalizeDescriptorFromStructure( DATA(TRAINIDX,:), Param_GLCM.pyramid,8 );
    TRAINData = cell2mat(TRAINData);
    % Pick a subset
    if SUBSET_SIZE <= length(TRAINData)
        SubsetInd = randperm(length(TRAINData));
        SubsetInd = SubsetInd(1:SUBSET_SIZE);
    else
        SubsetInd = 1:length(TRAINData);
    end
    
    if length(SubsetInd) < WORDS
        VOCAB = ML_VocabGeneration( TRAINData(SubsetInd,:), length(SubsetInd) );
    else
        VOCAB = ML_VocabGeneration( TRAINData(SubsetInd,:), WORDS );   
    end
    
    clear TRAINData;
    
    
    REFORMALIZEDDATA = ML_NearestWord( UnFormattedData, VOCAB,WORDS );

    % Reformalulate back into a Structure
   % DATA = FN_ReformalizeDescriptorToStructure( WordRepresentation, Param_GLCM.pyramid,WORDS );

    
    
    if USE_LINEAR_SVM
    %% TEST USING LINEAR SVM

        LinearSVM_Vocabulary{k} = VOCAB;
        
        if length(GN) > 2
                [ LinearSVM_Confusion{1},...
            LinearSVM_Accuracy(1),...
            LinearSVM_Probablity_estimates{1},...
            LinearSVM_Training_model{1},...
            LinearSVM_Final_decision{1},...
            LinearSVM_Actual_answer{1} ]...
            = ML_MultiClassLibLinearSVM(REFORMALIZEDDATA ,TESTIDX,TRAINIDX,G,GN,LINEAR_SVM_VERBOSE );
        else
                [ LinearSVM_Confusion{1},...
            LinearSVM_Accuracy(1),...
            LinearSVM_Probablity_estimates{1},...
            LinearSVM_Training_model{1},...
            LinearSVM_Final_decision{1},...
            LinearSVM_Actual_answer{1} ]...
            = ML_TwoClassLibLinearSVM(REFORMALIZEDDATA ,TESTIDX,TRAINIDX,G,GN,LINEAR_SVM_VERBOSE );
        end
        

        
    end
    
    if USE_RANDOM_FOREST
    %% TEST RANDOM FOREST
    [RandomForest_Confusion{1},...
        RandomForest_Accuracy(1),...
        RandomForest_Probablity_estimates{1},...
        RandomForest_Training_model{1},...
        RandomForest_Final_decision{1},...
        RandomForest_Actual_answer{1} ] = ML_TwoClassForest(REFORMALIZEDDATA,...
        TESTIDX,...
        TRAINIDX,...
        G,...
        GN,...
        RANDOM_FOREST_TREES,...
        RANDOM_FOREST_VERBOSE,...
        RANDOM_FOREST_VERBOSE_MODEL);
        RandomForest_Vocabulary{1} = VOCAB;
    
    end
    
    


%% End of the final test




RAND_FOREST = cell(7,1);
LINEAR_SVM = cell(7,1);
if USE_RANDOM_FOREST
RAND_FOREST{1}  =   RandomForest_Confusion;
RAND_FOREST{2}  =   RandomForest_Accuracy;
RAND_FOREST{3}  =   RandomForest_Probablity_estimates;
RAND_FOREST{4}  =   RandomForest_Training_model;
RAND_FOREST{5}  =   RandomForest_Final_decision;
RAND_FOREST{6}  =   RandomForest_Actual_answer;
RAND_FOREST{7}  =   GN;
RAND_FOREST{8}  =   RandomForest_Vocabulary;
end
if USE_LINEAR_SVM
LINEAR_SVM{1}   =   LinearSVM_Confusion;
LINEAR_SVM{2}   =   LinearSVM_Accuracy;
LINEAR_SVM{3}   =   LinearSVM_Probablity_estimates;
LINEAR_SVM{4}   =   LinearSVM_Training_model;
LINEAR_SVM{5}   =   LinearSVM_Final_decision;
LINEAR_SVM{6}   =   LinearSVM_Actual_answer;
LINEAR_SVM{7}   =   GN;
LINEAR_SVM{8}   =   LinearSVM_Vocabulary;
end

end
