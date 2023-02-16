/ dictionary of level:value
.log.levels:`fatal`error`warn`info`debug`trace!1+til 6;

/ sets the current log level
.log.setLevel:{[level]
  .log.currentLevel:level
 };

/ ANSI colour codes
.log.colors:(!) . flip(
  (`trace; "\033[0;35m");
  (`debug; "\033[0;36m");
  (`info;  "\033[0;32m");
  (`warn;  "\033[0;33m");
  (`error; "\033[0;31m");
  (`fatal; "\033[4;31m");
  (`reset; "\033[0m")
  )

/ Message that the logger will print to stderr/stdout wrapping in ansi color codes
.log.msg:{[level;msg;outputs]
    / dont print logs if below currentlevel
    if[not level in where .log.levels  <= .log.levels .log.currentLevel;
       : ()
    ];
    / set handle to stderr or stdout
    h:$[level in `error`fatal; -2; -1];
    / check if outputs is a dictionary or table type
    dictTable:.Q.qt[outputs] or 99h=type outputs;
    / if true, set msgOutputs to ""
    msgOutputs:$[dictTable;"";outputs];
    / list of args
    args:(string[.z.p];.log.colors[level],upper[string level],.log.colors[`reset];msg);
    / generates a messages
    msg:{$[10=type x; x; -11h=type x; string[x]; .Q.s1 x]} each args;
    / writes message to stderr/stdout seperated by delim " "
    h @ " " sv msg,:$[count msgOutputs;"- ",.Q.s1 msgOutputs;""];
    / if dictionary or table, do a show after the msg output
    if[dictTable;show outputs];
    / if loglevel fatal, drop out
    if[level=`fatal;
        exit 1
    ];
 };

/ Different log levels
.log.trace:.log.msg[`trace];
.log.debug:.log.msg[`debug];
.log.fatal:.log.msg[`fatal];
.log.error:.log.msg[`error];
.log.warn:.log.msg[`warn];
.log.info:.log.msg[`info];

/ Set default level to be INFO
.log.setLevel`info;