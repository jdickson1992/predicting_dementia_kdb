//=============================================================================
// Python library/module imports
//=============================================================================

.log.info["Script for importing python library/module packages";()];

//python libraries
pd:.p.import`pandas
pp:.p.import`pandas.plotting;
np:.p.import`numpy
plt:.p.import`matplotlib.pyplot
sns:.p.import`seaborn
display:.p.import`IPython.display
warning:.p.import`warnings
warning[`:filterwarnings]"ignore";

stratifiedKFold:.p.import[`sklearn.model_selection;`:StratifiedKFold];
train_test_split:.p.import[`sklearn.model_selection;`:train_test_split]
cross_val_score:.p.import[`sklearn.model_selection;`:cross_val_score]
roc_curve:.p.import[`sklearn.metrics;`:roc_curve]
acc_score:.p.import[`sklearn.metrics;`:accuracy_score]
recall_score:.p.import[`sklearn.metrics;`:recall_score]
precision_score:.p.import[`sklearn.metrics;`:precision_score]
auc:.p.import[`sklearn.metrics;`:auc]
classification_report:.p.import[`sklearn.metrics;`:classification_report]
confusion_matrix:.p.import[`sklearn.metrics;`:confusion_matrix]
RandomizedSearchCV:.p.import[`sklearn.model_selection;`:RandomizedSearchCV]
GridSearchCV:.p.import[`sklearn.model_selection;`:GridSearchCV]
scaler:.p.import[`sklearn.preprocessing;`:StandardScaler];
smote:.p.import[`imblearn.over_sampling;`:SMOTE];
sm:smote[`k_neighbors pykw 5; `random_state pykw seed];

//Outlier and PCA analysis
isolationForest:.p.import[`sklearn.ensemble;`:IsolationForest];
PCA:.p.import[`sklearn.decomposition;`:PCA];
.p.import[`mpl_toolkits.mplot3d;`:Axes3D];

//Classification algos
dt:.p.import[`sklearn.tree;`:DecisionTreeClassifier]
gnb:.p.import[`sklearn.naive_bayes;`:GaussianNB]
lr:.p.import[`sklearn.linear_model;`:LogisticRegression]
rf:.p.import[`sklearn.ensemble;`:RandomForestClassifier]
rfr:.p.import[`sklearn.ensemble;`:RandomForestRegressor]
svc:.p.import[`sklearn.svm;`:SVC]
baseline:.p.import[`sklearn.dummy;`:DummyClassifier];
lda:.p.import[`sklearn.discriminant_analysis;`:LinearDiscriminantAnalysis];
nn:.p.import[`sklearn.neural_network;`:MLPClassifier];

//Boosting algorithms
ada:.p.import[`sklearn.ensemble;`:AdaBoostClassifier]
gb:.p.import[`sklearn.ensemble;`:GradientBoostingClassifier]

//ML algo name/func mapping
algoMappings: (!) . flip(
 (`NaiveBayes                   ; gnb);
 (`LogisticRegression           ;  lr);
 (`DecisionTreeClassifier	;  dt);
 (`SVM				; svc);
 (`RandomForests		;  rf);
 (`Adaboost			; ada);
 (`GradientBoost		;  gb));

//Default linear classifiers
linearClassifiers: (!) . flip(
 (`BaselineModel                ;  baseline[`random_state pykw seed]);
 (`LogisticRegression           ;  lr[`random_state pykw seed]);
 (`LinearDiscriminantAnalysis   ;  lda[]));

//Default nonlinear classifiers
nonLinearClassifiers: (!) . flip(
 (`NeuralNetworks                ;  nn[`random_state pykw seed]);
 (`SVM                           ;  svc[`kernel pykw `linear;`random_state pykw seed;`probability pykw 1b]);
 (`NaiveBayes                    ;  gnb[]));

//Default tree classifiers
treeBasedClassifiers: (!) . flip(
 (`DecisionTreeClassifier      ;  dt[`random_state pykw seed]);
 (`RandomForests               ;  rf[`random_state pykw seed]);
 (`Adaboost                    ;  ada[]); 
 (`GradientBoost               ;  gb[]))
