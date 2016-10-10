xquery version "1.0-ml";

(: Ticketing functions that do require a document update :)
module namespace m="http://marklogic.com/datascience/ticketing-update";

declare option xdmp:update "true";

declare function m:ticket-update($ticket as xs:string,$pid as xs:positiveInteger,
  $size as xs:int,$mytotal as xs:int,$mycomplete as xs:int,$output as node()*) {
  xdmp:spawn-function(function() {
    (xdmp:document-insert(
      "/datascience/tickets/" || $ticket || "/" || xs:string($pid) || ".xml",
      <ticket><id>{$ticket}</id><pid>{$pid}</pid><size>{$size}</size>
      <total>{$mytotal}</total><complete>{$mycomplete}</complete>
      <finished>{
        if ($mytotal eq $mycomplete) then fn:true() else fn:false()
        }</finished>
      {
        if (0 eq $mycomplete) then
          <started>{fn:current-dateTime()}</started>
        else
          let $started := xs:dateTime(fn:doc("/datascience/tickets/" || $ticket || "/" || xs:string($pid) || ".xml")/ticket/started)
          let $now := fn:current-dateTime()
          let $duration := $now - $started
          return
          (
            <started>{$started}</started>
            ,
            if ($mycomplete eq $mytotal) then
              (
                <finished>{$now}</finished>
              )
            else ()
            ,
            <rate-per-second>{$mycomplete div fn:seconds-from-duration($duration)}</rate-per-second>
            ,
            <duration>{$duration}</duration>
          )
        }
        {
          if (fn:not(fn:empty($output))) then <return-value>{$output}</return-value> else ()
        }</ticket>,
      xdmp:default-permissions(),(xdmp:default-collections(),"/datascience/tickets")
    ),
    xdmp:commit()
    )
  },
    <options xmlns="xdmp:eval">
      <database>{xdmp:database()}</database>
      <transaction-mode>update</transaction-mode>
    </options>
  )
};
