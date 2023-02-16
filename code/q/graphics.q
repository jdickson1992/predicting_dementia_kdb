//=======================================
// Exploratory data analysis
//=======================================

.log.info["Script contains functions used for exploratory data analysis";()];

//config for sns/plt plots
//sets font,size,palette for graphs
//init at start of EDF
//graphics.config[]
graphConfig: {
 `colours set (enlist `color)!(enlist `r`k`b);
 `csfont_options set (`fontname`weight`color`size!`monospace`bold`b`large);
  sns[`:set][`context pykw `paper;`palette pykw `winter_r;`style pykw `darkgrid; `font_scale pykw 1.5]; }

//t = data table
//x = column that will be visualised
//y = the count of column x for each value of y
factorPlot:{[t;x;y]
 df: tab2df[t];
 sns[`:factorplot][`x pykw x;`data pykw df;`hue pykw y;`kind pykw `count;`legend pykw 1b;`size pykw 6];
 plt[`:show][];
 }

//side by side count plots
//shows distribution of column/s within dataset
//t = data table
//x = distribution of col x. LHS of the axis
//y = distribution of col y. RHS of the axis
countPlot:{[t;x;y]
 fig:plt[`:figure][];
 fig[`:set_size_inches][22.5;16.5];
 ax1: fig[`:add_subplot]["121"];
 ax2: fig[`:add_subplot]["122"];
 // fill nulls temporarily
 data:0^t[x];
 sns[`:countplot][data;`ax pykw ax1];
 sns[`:countplot][data;`ax pykw ax2];
 plt[`:show][];}


//t = data table
//x = distribution feature
//y = The header of the graph - string type
//z = column
facetGrid:{[t;x;y;z]
 t:![t;enlist(=;z;0Ni);0b;`symbol$()];
 df: tab2df[t];
 grid:sns[`:FacetGrid][`data pykw df;`hue pykw x;`hue_kws pykw colours;`size pykw 8];
 grid[`:map][sns[`:kdeplot];z;`shade pykw 1b];
 plt[`:legend][`loc pykw `best];
 plt[`:title][y,string[z]; csfont_options];
 plt[`:show][];
 }

//draws a columns boxpot
//x is a dictionary.Maps column:column's values
boxPlot:{[x]
 if[not 99h=type x; :"Dictionary input expected"];
 fig:plt[`:figure][`figsize pykw (20;12)];
 ax:fig[`:add_subplot][111];
 bp:ax[`:boxplot][value x];
 ax[`:set_xticklabels][key x];
 plt[`:show][] }

//plot pairwise relationships in a dataset
//t= table where each row is a variable and each row is an observation
//x = hue value. Each value of x is plotted in a different colour to illustrate aspects in data.
//.graphics.pairPlot[select asf,nwbv,etiv from data;`mF]
pairPlot:{[t;x]
 if[not 98h=type t;'"Please set x argument to be a table"];
 plt[`:figure][`figsize pykw (30;20)];
 sns[`:pairplot][tab2df t;`hue pykw x; `markers pykw `o`s];
 plt[`:show][]; }

//plots Pearson's heatmap showing correlation between features
heatMap:{[t]
 sns[`:set][`style pykw `white];
 corr:tab2df[t][`:corr][`method pykw `pearson];
 mask:np[`:zeros_like][corr;`dtype pykw np[`:bool]];
 f:plt[`:subplots][`figsize pykw (12;8)];
 sns[`:heatmap][corr;`annot pykw 1b;`linewidths pykw .5;`fmt pykw ".2f"];
 plt[`:title] "Pearson heatmap";
 plt[`:show][];
 }

//draws a whiskerplot 
//calls pandas melt function that converts a wide-form df to a long-form df
//whiskerPlot[tab]
whiskerPlot:{  
 sns[`:boxplot][`x pykw `variable; `y pykw `value;`data pykw pd[`:melt] tab2df x];
 plt[`:figure][`figsize pykw (20,10)];
 plt[`:show][];
 }

//also draws a whiskerplot/boxplot
//takes dict input
//boxPlot[dict]
boxPlot:{
 if[not 99h=type x; :"Dictionary input expected"];
 fig:plt[`:figure][`figsize pykw (20;12)];
 ax:fig[`:add_subplot][111];
 bp:ax[`:boxplot][value x];
 ax[`:set_xticklabels][key x];
 plt[`:show][] }

//Seaborn kdeplot plot
kdePlot:{[t;c;f]
 kde:sns[`:kdeplot][t[c];`ax pykw f]}

//Takes a scaler and transforms the data
//Shows 2 graphs on 1 axis - before scaling [LHS] / after scaling [RHS]
scaleBeforeAfter:{[scaler;tab;col]
 fig:plt[`:figure][];
 ax1: fig[`:add_subplot]["121"];
 kdePlot[tab;;ax1] each col;
 ax1[`:title][`:set_text]"Before scaling";
 ax1[`:title][`:set_size]30;
 t:@[tab;cols tab;scaler];
 ax2: fig[`:add_subplot]["122"];
 kdePlot[t;;ax2] each col;
 ax2[`:title][`:set_text]"After scaling";
 ax2[`:title][`:set_size]30;
 fig[`:set_size_inches][24.5;14.5];
 fig[`:tight_layout][];
 plt[`:show][];
 }

//=======================================
// Appendix
//=======================================
//Plot datapoints in 3D space
//Hightlight outliers relative to other data values
scatter3d:{[data;outliers]
  fig:plt[`:figure][];
  fig[`:set_size_inches][20.5;14.5];
  ax:fig[`:add_subplot][111; `projection pykw "3d"];
  ax[`:set_zlabel]["x_composite_3"];
  ax[`:scatter][data[;0];data[;1];zs:data[;2]; `s pykw 4; `lw pykw 4; `label pykw "inliers";`c pykw "green"];
  ax[`:scatter][data[;0][outliers];data[;1][outliers];data[;2][outliers]; `s pykw 100; `lw pykw 4;`marker pykw `x;`label pykw "outliers";`c pykw "red"];
  ax[`:legend][];
  plt[`:show][]; }

