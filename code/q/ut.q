//-------------------------------------------------------------------------
//Utility Function namespace 
//-------------------------------------------------------------------------
.log.info["Script for utility functions";()];

//Define a function to apply camelCase format to column headers
camelCase:{ 
  x:@[x;raze x ss/: "_/=";:;" "];
    x:?[-1=deltas s:" "=x; upper x; lower x];
      `$x where not[s]}

//camelCase csv column headers
csvHeaders:{[file] {camelCase[x]} each ["," vs first read0 hsym file]};

//maps datatypes to name
dtypes:"bgxhijefcspmdznC"!`boolean`guid`byte`short`int`long`real`float`char`symbol`timestamp`month`date`datetime`timespan`string;

//rename a column within a table
//returns 1 row illustrating change has been applied
renameCol:{if[11h=type x;x:(!). 1#/:x];
   t: @[c;where(c:cols y)in key x;x] xcol get y;
     @[`.;y;:;t]; : 1#t}

//creates a number range between 2 end points
range:{x+til 1+y-x}

//drop column/s from a table
dropCol:{ ![x;();0b;] $[1=count y;y:(),y;y]}

//first whereIn[key .q;cols data]
whereIn: {y where y in x}

//shuffle values
shuffle:{neg[count x]?x}

//Shuffle the column order of a table
//table reference is the input
shuffleCols:{[t] 
  x: get t;
  t set keys[x]xkey shuffle[cols x]xcols 0!x; 
  : get t }

//Returns dimensions of the dataset
shape:{ `rows`columns set' 2#string -1_count each first scan get x;
     .log.info["Shape of ",string[x]," table: ",rows," rows ",columns, " columns";()]}

//percentile - used to calculate q25/q75
pctl:{[p;x] x iasc[x] -1+ceiling p*count x}

//Interquartile range
iqr:{(-) . pctl[.75 .25; x]}

//q describe method - only works on numerical cols
//computes min,median,max,avg,q25/75,iqr and standard deviation
describe:{[t]
 //Extract non-numerical columns
 c:exec c from meta[t] where not t in "ifj"; 
 //Remove them from table
 t:![t;();0b;c];
 //Applying functions to each numerical column of table
 d:{`Field`Count`Mean`Min`Max`Median`q25`q75`STD`IQR!raze(x;(count; avg; min; max;med;pctl[.25;];pctl[.75;];dev;iqr)@\:y[x])}[;t] each cols t;
 : prettyPrint d}

//q equivalent to pythons info method
//returns summary table with datatypes, nulls, unique counts
info:{[t]
 -1"RangeIndex: ",string[count t]," entries , 0 to ",string[-1+count t];
 -1"Columns total: ",string[count c:cols t];
 dt:dtypes[exec t from meta t];
 uniq:{count distinct x[y]}[t;] each cols t;
 nulls: `int${1b = sum any null x[y]}[t;] each cols t;
 show stats:([column: c]nullExists:nulls;uniqVals:uniq; datatype:dt);
 -1"Memory usage: ",string[(-22!t)%s*s:1024]," MB";}

//Executes a function over each key/value dict pair. eachKV = for each key/value pair of a dict.
//for e.g. for d:`key1`key2!(arg1;arg2), calling a function f using eachKV[f] d returns:
//key1 | f[key1;arg1]
//key2 | f[key2;arg2]
eachKV:{key[y]x'y};

//split a list x into y lists of even length (or close)
//splitList[`age`ses`mmse`cdr`educ`visit;3]
splitList:{value til[y]!#[y,0N;x]}

//Returns the mode of a list. Note, if there are more than one modes, it will return the first mode
mode:{first where max[c]=c:count each d:group x}

//-------------------------------------------------------------------------
// Websockets for HTML5 GUI
//-------------------------------------------------------------------------
//table for tracking conns
activeWSConnections: ([] handle:(); connectTime:())

//when a connection is open, upsert to table
.z.wo:{`activeWSConnections upsert (x;.z.t)}

//when a connection closes, remove from table
.z.wc:{ delete from `activeWSConnections where handle =x}

//customised msg handler for websockets
//all ws msgs will be processed by this function
.z.ws:{
 d:value x;
 //Check models have been evaluated
 if[not modelsTrained;
    neg[.z.w] .j.j "Models havent been trained yet. Cant predict a score!";
    :()
 ];
 //Get classifier from dict
 clf:d[`algo];
 //If boruta is enabled, use features computed by boruta algo, if not default to only using mmse,educ and age fields 
 $[`Y=d`boruta;borutaFeatures:`nwbv`mmse`educ;borutaFeatures:`mmse`educ`age];
 //Drop algo and boruta fields from dict
 d:(`algo`boruta) _ d;
 //Change to table fmt and assign it to global t table
 `t set enlist d;
 //call pipeline fn to clean the dataset
 pipeline[`t;trainingStats;cols[t] except borutaFeatures];
 //Convert to python array
 tab2Array[`t];
 //get optimal parameters for classifier
 p:optimalModels[clf;`parameters];
 //configure new model using opt params
 m:algoMappings[clf][pykwargs p];
 //fit new model with training sets
 m[`:fit][X_train;y_train];
 //predict probability of subject being demented
 pred:m[`:predict_proba][t]`;
 res: raze pred;
 //convert to json and send output back to the handle which made the request
 neg[.z.w] .j.j "F"$.Q.fmt[5;3] res 1;
 }