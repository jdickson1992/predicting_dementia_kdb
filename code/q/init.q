
.init.main:{
    system"c 200 200";
    system"l code/q/log.q";
    seed::42;
    .log.warn["Using random seed ",string[seed]," for reproducible results";()];
    system"S ",string[seed];
    .log.warn["Setting the global modelsTrained to False. Web GUI wont be able to use models until this is set to True";modelsTrained::0b];
    .init.load each `ut`lib`mlf`graphics;
    .log.info["Opening port on 9090 to allow the Web GUI to connect";()];
    system"p 9090";
 }

.init.load:{[script]
  script:string[script],".q";
  .log.info["Loading in script ";script];
  @[system;"l ","code/q/",script;{.log.error["Cant load in script ",x,". Received error: ",y;()]}[script]]
 };

.init.main[];