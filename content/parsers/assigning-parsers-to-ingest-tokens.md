---
title: Assigning Parsers to Ingest Tokens
---

When you send data to Humio must specify which repository to storage the data
in and which parser to use for ingesting the data. The best way of doing this is
to assign a specific parser to the Ingest API Token used to authenticate the client.

To change the assigned parser in the UI, go to the parser you wish to assign.
Then go to `Settings` -> `API Tokens` and click assign on the token that is used
by the clients in question.

{{< figure src="/pages/assign-ingest-tokens/assign-parser.png" width="80%" caption="Assigning a parser to an ingest token using the parser's settings page." >}}

Assigning a parser to the API Token is the recommended way of specifying the parser to use for ingest
since it allows you to change parser in Humio without changing the client.  

__Q: What happens if both the #type field is set and the token has a parser assigned?__  
_A: The parser assigned to the parser will be used in case of conflicts._
