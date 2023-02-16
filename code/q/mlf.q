//=============================================================================
// machine learning namespace functions
//=============================================================================

.log.info["Script for machine learning functions";()];

//converts a q table into a pandas df
tab2df:{[x] 
 r:.p.import[`pandas;`:DataFrame;x][@;cols x];
 $[count k:keys x;r[`:set_index]k;r] }

//prints q table as dataframe
prettyPrint:{ `.[`display][`:display] tab2df x;};

//key table that stores eachsplits column order before kdb+->python matrix transform
//Allows for easy reversal python->kdb+
transCols:([split:()] columns:())

//Converts a q table to python-like array
//In the process updates transCols table with column order (for easy reversal)
tab2Array:{
 upsert[`transCols;(x; cols get x)];
 .log.info[string[x]," converted to array";()];
 x set flip value flip get x}

//Convert array back to a q table
//references tansCols table
array2Tab:{
 .log.info[string[x]," reverted back to q table";()];
 x set flip (raze value[transCols x])!flip[get x] }

//returns training and test splits
//pct determines size of test split
//random seed is set so reproducible splits are obtained each time fn is called
//.trainTestSplit[tab1;tab2;0.2;42]
//feat=feature table
//targ=target table
trainTestSplit:{[feat;targ;pct;seed] 
 system"S ",string[seed];
 //round the distribution to the nearest integer
 dist:floor 0.5 + (1-pct)*count feat;
 idx:exec i from feat;
 //random selection without duplication on whole indice list
 splitIdx:neg[dist]?idx;
 //mappings of train,test splits to their values
 dict: (!) . flip(
 (`X_train         ;  feat[splitIdx] );
 (`X_test          ;  feat[idx except splitIdx] );
 (`y_train         ;  targ[splitIdx] );
 (`y_test          ;  targ[idx except splitIdx]));
 eachKV[set] dict; }

//=============================================================================
// Feature Engineering functions
//=============================================================================

//table to keep track of outliers
outliers:flip `column`index`outlier!()

//Detects outliers using the z-score method
//Z score = (x -mean) / std. deviation
//t and c are the table/column where the z-score method will be executed
//r is the results table where nay outliers will be inserted
outlierDetect:{[t;c;r]
 v:t c;
 if[0< count o:where 3<=abs %[v-avg[v];dev v];
 r upsert (c;o;v o)] }

//fn that takes care of outliers
//method is decided by users input x
//Can either be 1.keep 2.delete 3.logTransform 4.winsorize
//t is a reference of the outlier table
outlierTransform:{[x;t]
 if[(not x in `keep`delete`logTransform`winsorize)|(not -11h=type t);
    '"1.Please use relevant transformation:`keep`delete`logTransform`winsorize\n2.Please pass outlier table as a reference: `outliers"];
 //if x=`keep, do nothing, leave outliers in dataset
 if[x=`keep;(::)];
 //if x=`delete, remove the outlier rows from the X_train/y_train dataset
 if[x=`delete;
    idx:distinct raze exec index from t;
    -1 "Removing following row indexes from X_train and y_train: ", " " sv string(idx);
    {![x;enlist (in;`i;`idx);0b;`symbol$()]} each `X_train`y_train];
 //if x=`logTransform, perform a logarithmic transformation on each outlier value. Replace outlier value with newly computed log-transformation
 if[x=`logTransform;
    update transformed:{log x}'[outlier] from t;
    oc:exec feature from t;
    {[x;c]
     .log.warn["For the ",string[c]," feature, replacing outlier values:";?[x;enlist (=;`feature;enlist c);0b;(enlist`outlier)!enlist`outlier]];
     .log.info["With the log-transformed values:";?[x;enlist (=;`feature;enlist c);0b;(enlist`transformed)!enlist`transformed]];
     ![`X_train;enlist (in;`i;(x;enlist c;enlist`index));0b;(enlist c)!enlist (x;enlist c;enlist`transformed)]}[`outliers;] each oc];
  if[x=`winsorize;
     oc:exec feature from t;
     winsorize[X_train;`outliers;] each oc;
     {[x;c]
     .log.warn["For the ",string[c]," feature, replacing outlier values:";?[x;enlist (=;`feature;enlist c);0b;(enlist`outlier)!enlist`outlier]];
     .log.info["With the winsorize value:";?[x;enlist (=;`feature;enlist c);0b;(enlist`winsor)!enlist`winsor]];
     ![`X_train;enlist (in;`i;(x;enlist c;enlist`index));0b;(enlist c)!enlist (x;enlist c;enlist`winsor)]}[`outliers;] each oc] }


//winsorize[X_train;`outliers;] each `visit`mmse`cdr
//any value > 95th percentile, is replaced with the max value of the 95th percentile
//any value < 5th percentile, is replaced with the min value of the 5th percentile
winsorize:{[t;o;c]
 pct5:pctl[.5;t c];
 pct95:pctl[.95;t c];
 //![o;enlist (=;`feature;enlist c);0b;(enlist`winsor)!enlist ((';?);(>;`outlier;`pct95);`pct95;`pct5)]
 update winsor:?'[outlier>pct95;pct95;pct5] from o where feature=c }

//Adds adjacent true column to target table and returns a pivot table
pivotTab:{[t;targ]
 prePvt:?[t;();0b;(targ,`true)!(targ;1)];
 pvtTab:0^{((union/) key each x)#/:x} ?[prePvt;();(enlist targ)!enlist targ;(lsq;targ;`true)];
 : pvtTab }

//get dummies fn
//converts categorical variables into dummy variables 
//t=training table
//v=variable that will be converted to dummy/indicator variable
//r=a symbol reference. Will save the results to a global r value
dummies:{[t;v;r]
  pvt: t lj pivotTab[t;v];
  t:(enlist v) _ pvt;
  prettyPrint t;
  @[`.;r;:;t]; }

//correlation matrix
//returns a pearsons heatmap with a table detailing correlation between adjacent features
corrMatrix:{[t]
 c:exec c from meta t where t in "Cs";
 t:u cor/:\:u:c _ flip t;
 t:1!`feature xcols update feature:cols t from value t;
 : heatMap t}

//returns the x highest correlation feature_target combinations in a dataset
//t  = table 
//tc = target columns  
//x  = number of features_target combos user wants back
corrPairs:{[t;tc;n]
 c:exec c from meta[t] where t in "Cs";
 //calculates correlation between all numerical features in t
 t:u cor/:\:u:c _ flip t;
 //groups features, pairwise, with target columns
 p:raze except[cols t;tc]{x,/:y except x}\:tc;
 //returns n highest correlated pairs 
 : n#desc p!t ./: p}

//one hot encoding 
//encodes symbol columns to numerical cols
//takes table as symbol reference
hotEncode:{[t;c]
 if[not -11h= type t;'"Please pass table as reference"];
 t1:get t;
 v:t1[c]=/:distinct[t1 c];
 k: distinct t1 c;
 r:`float$k!v;
 : get t set dropCol[t1;c],'flip[r]}

//imputation - replace null values in numerical columns with median val
//ignore string/symbol columns as a median value cant be inferred
impute: {[t;m]
 if[(not m in `med`avg`mode)|(not -11h=type t);'"1.Please use either:`med`avg`mode\n2.Please pass training table as a reference: `X_train"];
 c:{x!x}exec c from meta[t] where t in "ifjh";
 t1:?[t;();0b;c];
 .log.warn["Found nulls in the following columns: ", "," sv string n: where any null t1;()];
 .log.info["Replacing nulls with the columns ",string[m]," value";()];
 @[t;n;{x[y]^y}[value string[m]]]}

//Detects outliers using the z-score method
//Z score = (x -mean) / std. deviation
//t and c are the table/column where the z-score method will be executed
//r is the results table where nay outliers will be inserted
outlierDetect:{[t;c;r]
 v:t c;
 if[0< count o:where 3<=abs %[v-avg[v];dev v];
 r upsert (c;o;v o)] }

//A training statistics table used to capture import metrics associated with the training data
trainingStats:([feature:()] maxVal:(); minVal:(); medVal:(); avgVal:(); stdVal:())

//Gathers key metrics about the training data
//t = training table
//s = output table to store metrics
//c = column to check
//Each numerical column is enforced to a float type within the functional apply - allows for rows to be upserted correctly
trainInfo:{[t;s;c]
 @[t;c;{x:`float$x;upsert[y;(z;max x;min x;med x; avg x; dev x)]}[;s;c]]}

//Standard scaler method 
stdScaler:{(x-avg x)%dev x}

//Minmax scaler method
minMaxScaler:{(x-m)%max[x]-m:min x}

//transforms columns,c, in a table t using a stats table st with method m
transform:{[t;st;c;m]
 .log.info[string[m]," executing";()];
 @[t;c;:;{[t;st;c;m] st[c;m] t[c]}[t;st;;m] each c] }

//automates machine learning cleaning/feature engineering steps
//log transforms, hot encodes, std-scales and imputes
//returns q table ready to be evaluated
//t=table being transformed
//s=training stats table which contain mean,max,min,scaling functions
//c=collinear/irrelevant columns that will be dropped
pipeline:{[t;s;c]
 if[not -11h= type t;'"Please pass table as reference"];
 $[1< count skc:`mrDelay`etiv inter cols t; skc; skc:first skc];
 .log.info["Log transforming highly-skewed columns";()];
 @[t;skc;{log(1+x)}];
 .log.info["Hot-encoding sym columns";()];
 hotEncode[t;] each exec c from meta[t] where t in "s";
 .log.info["Dropping irrelevant features";()];
 dropCol[t;c];
 `x1 set t;
 .log.info["Performing imputation and standard scaling on ",string[t];()];
 {[t;s;c;m] transform[t;s;c;m]}[t;s;cols t;] each `imputer`stdScaler;
 .log.info["Pipeline transform complete";()];
 : prettyPrint get t }


//=============================================================================
// Estimator evaluation functions
//=============================================================================

//Computes the Diagnostic odds Ratio 
dorScore:{[m]
 TN:m[0;0];
 FP:m[0;1];
 FN:m[1;0];
 TP:m[1;1];
 dor:(TP%FP)%(FN%TN);
 : dor }

//Returns a classification Report
//k =  name of classifier
//v =  the ml algorithm with its' parameters 
//m =  symbol to display if parameters of ml algo have been hypertuned or are they default
//for e.g.:
//lr:.p.import[`sklearn.linear_model;`:LogisticRegression]
//classReport[`LogisticRegression;lr[`random_state pykw seed];`Default]
//or
//f:classReport[;;`Default]
//eachKV[f] linearClassifiers
classReport:{[k;v;m]
 v[`:fit][X_train;y_train];
 y_pred_probs: v[`:predict_proba][X_test]`;
 demented_class_probs: y_pred_probs[;1];
 //show demented_class_probs;
 y_pred_classes: v[`:predict][X_test];
 `fpr`tpr`thresholds set' roc_curve[y_test; demented_class_probs]`;
 auc_score:auc[fpr;tpr]`;
 labels:string[k]," auc_score= ",string[auc_score];
 train_acc:v[`:score][X_train;y_train]`;
 test_acc:v[`:score][X_test;y_test]`;
 .log.info[labels;()];
 plt[`:plot][fpr;tpr;`linewidth pykw 2;`label pykw labels;`alpha pykw 0.45];
 target_names:`Nondemented`Demented;
 .log.info["Classification report showing precision, recall and f1-score for each class:";()];
 -1 classification_report[y_test;y_pred_classes;`target_names pykw target_names]`;
 cm:confusion_matrix[y_test;y_pred_classes]`;
 -1"DOR score: ",string dscore:dorScore[cm];
 -1 (60#"="),"\n";
 upsert[`scores;(k;m;dscore;train_acc;test_acc;auc_score)]
 }


//Evaluates machine learning algorithms
//Calls classReport to ascertain accuracy,auc,dor sores
//Plots each algorithm on a ROC curve diagram
//for e.g.
//d = dictionary with name of classifier and the classifier with settings ready to be executed
//m = symbol to display if parameters of ml algo have been hypertuned or are they default
//evaluateAlgos[linearClassifiers;`noTuning]
evaluateAlgos:{[d;m]
 plt[`:figure][`figsize pykw (12;8)];
 f:classReport[;;m];
 eachKV[f] d;
 plt[`:legend][`loc pykw "lower right"];
 plt[`:title]["Comparing Classifiers"];
 plt[`:plot][[[0 1];[0 1]];`linewidth pykw 2]; /x=y line
 plt[`:xlim][0.0; 1.0];
 plt[`:ylim][0.0; 1.05];
 plt[`:xlabel]["False Positive Rate"];
 plt[`:ylabel]["True Positive Rate"];
 plt[`:show][];
 }


//Tunes algorithms hyperparameters
//pspaces:(`SVM`LogisticRegression`DecisionTreeClassifier`Adaboost`GradientBoost`RandomForests)!(svcParams;lrParams;dtParams;adaParams;gbParams;rfParams)
//f:hyperTune[;;`RandomizedSearchCV]
//eachKV[f] pspaces;
hyperTune:{
 -1 (60#"="),"\n";
 .log.info["Hypertuning classifier: ",string[x];()];
 start:.z.p;
 //Dict look-up to find algorithm's parameter space
 clf:algoMappings x;
 //If model is svm, enable probability.Set same seed for each classifier
 $[x=`SVM;
   mdl:clf[`random_state pykw seed; `probability pykw 1b]; 
   mdl:clf[`random_state pykw seed]];
 //Check if optimizer method is valid, if not bomb out
 if[not z in `GridSearchCV`RandomizedSearchCV;
   : "Use GridSearchCV or RandomizedSearchCV as an optimizer!"];
 tuner:value string[z];
 //Naive Bayes does not perform grid search
 if[not x=`NaiveBayes;
    optParams:tunedEval[tuner[mdl;y;`scoring pykw "balanced_accuracy";`cv pykw 10]]];
 //Compute duration that grid-search/randomized grid search took
 .log.warn["Hypertuning parameters took: ",string[end:.z.p - start];()];
 if[x=`SVM; optParams[`probability]: 1b];
 //Track algorithm & its' optimal parameters, upsert to global table
 upsert[`optimalModels;(x;optParams)];
 //Call evaluateAlgos function
 evaluateAlgos[(enlist x)!enlist(clf[pykwargs optParams]);z]}


//Evaluates ML algos and returns their optimal parameters
tunedEval:{[mdl]
 clf: mdl;
 clf[`:fit][X_train;y_train];
 .log.info["Best score during gridSearch is ";clf[`:best_score_]`];
 .log.info["Best parameter set:";params:clf[`:best_params_]`];
 trainingAccuracy:clf[`:score][X_train;y_train]`;
 testAccuracy:clf[`:score][X_test;y_test]`;
 .log.info["Accuracy on training data ";trainingAccuracy];
 .log.info["Accuracy on test data ";testAccuracy];
 //return best params
 : params }


//Working out the most important features using the boruta algorithm
//Randomly permutes each column of x to create shadow featuress 
//only features that are above a threshold of importance,computed from the shadow features, are retained
//x= x_train table
//y= y_train table
//s= seed
boruta:{[x;y;s]
  system"S ",string[s];
  c:count cols x;
  nc:(`$"shadow_",/:string cols x);
  x_shadow:@[x;cols x;shuffle];
  x_shadow: nc xcol x_shadow;
  xboruta:x,'x_shadow;
  forest:rf[`n_jobs pykw -1;`class_weight pykw `balanced;`max_depth pykw 5];
  forest[`:fit][tab2df xboruta;y];
  featImp:forest[`:feature_importances_]`;
  trainFeatImp:featImp[til c];
  shadowFeatImp:featImp[c + til c];
  hits,: cols[x] where trainFeatImp > max[shadowFeatImp];
  nohits,: cols [x] where trainFeatImp < max[shadowFeatImp]}


//calls the boruta function to ascertain what functions are important 
//x=x_train table
//y=y_train table
//s=range of random seed we want to iterate over
//n=number of important features to select
//featSelect[X_train;y_train;1+til 20;5]
featSelect:{[x;y;s;n]
  boruta[x;y;] each s;
  .log.info["Following features fell within the area of acceptance: ";c:desc count each group hits];
  `borutaFeatures set key n#c;
  .log.warn["Following features fell within area of refusal/irresolution: ";desc count each group nohits];
  .log.info["Keeping top ",string[n]," boruta features for selection: ", "," sv string[borutaFeatures];()];
  .log.info["Reverting random seed back to ",string[seed];()];
  system"S ",string[seed] }

//=============================================================================
// Appendix functions
//=============================================================================
//Isolation forest technique to visualise outliers
//Selects a random feature and then computes a split value between max/min values of the said feature
//Uses a contamination value and then performs PCA
//Results are then visualized in 3D space
outlier3Dplot:{[d;t;c]
 //take numerical features only
 data:?[d;();0b;c!c];
 //The hue value is computed
 h:(exec sum count'[outlier] from t)%count[data];
 t: flip value flip data;
 -1"Using a contamination value: ",string[h];
 mdl:isolationForest[`n_estimators pykw 100; `max_samples pykw `auto; `contamination pykw h; `max_features pykw 1.0;`bootstrap pykw 0b; `random_state pykw seed];
 mdl[`:fit][t];
 pred:mdl[`:predict][t]`;
 /points classified as -1 are anomalous
 idx:where pred=-1;
 `anamoly`normal!(count where pred=-1;count where pred=1);
 //normalize and fit metrics to a PCA to reduce number of dimensions + plot them in 3D
 //reduce to k=3
 pca:PCA(`n_components pykw 3);
 stdscaler:scaler[];
 X:stdscaler[`:fit_transform][t];
 X_reduce: pca[`:fit_transform][X];
 X_reduce: X_reduce`;
 //Call 3dScatter plot function
 scatter3d[X_reduce;idx];}
