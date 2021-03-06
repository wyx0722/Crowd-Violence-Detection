function [ ACC, CMAT ,PREDICTLIST,AUC,AAUC,X,Y,PROB] = ML_TestClass( DATA,VOCABS,SVMMODELS,ACTUAL )
%ML_TESTCLASS Summary of this function goes here
%   Detailed explanation goes here

ACC = 0;
AAUC = 0;
%CMAT = zeros(2);
CMAT = cell(1,length(VOCABS));
PREDICTLIST = zeros(length(DATA),length(VOCABS));
AUC = cell(1,length(VOCABS));
X = cell(1,length(VOCABS));
Y = cell(1,length(VOCABS));
PROB = cell(1,length(VOCABS));
for i =1 : length(VOCABS)
    
    vs = size(VOCABS{i});
    BookData = ML_NearestWord(DATA,VOCABS{i},vs(1));
    sModel = SVMMODELS{i};
    [PREDICTLIST(:,i), accuracy, prob_estimates] =  predict(ACTUAL', sparse(BookData), sModel{1});
    ACC = ACC + accuracy(1);
    CMAT{i} = confusionmat(ACTUAL,PREDICTLIST(:,i));
    PROB{i} = prob_estimates;
    %CMAT = CMAT + confusionmat(ACTUAL,PREDICTLIST(:,i));
   %[X(i),Y(u),~,AUC(i)] = perfcurve(ACTUAL,PREDICTLIST(:,i),1)
   %AAUC = AAUC + AUC(i);
end

%AAUC = AAUC /length(VOCABS); 
ACC = ACC / length(VOCABS);
