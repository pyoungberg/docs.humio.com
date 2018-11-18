---
title: "Parsers"
category_title: "Overview"
date: 2018-03-15T08:19:58+01:00
weight: 650
---

- [Built-in Parsers]({{< relref "#built-in" >}})
- [Creating a custom parser]({{< relref "#custom" >}})

When data is sent to Humio it needs to be parsed into [events]({{< ref "events.md" >}})
before it is stored in a repository. _The only exception is if you send data
using Humio's JSON Ingest API which stores data as-is._

A parser takes any kind of text as input, it can be structured text (like JSON) or unstructured
text (like syslog or stdout). The parser extracts fields from the text which are
stored along with the input.

<figure>
{{<mermaid align="center">}}
graph LR;
  subgraph External Systems
    Ext1[Filebeat]
    Syslog[Syslog]
    Json1[Web Application]
  end

  subgraph Repository A
  Ext1 --> P1("<em>Parser</em><br/><b>accesslog</b>")
  Syslog --> P2("<em>Parser</em><br/><b>kv</b>")
  P1 --> S1("Storage")
  P2 --> S1
  end

  subgraph Repository B
  Json1 --> P3("<em>Parser</em><br/><b>custom-parser-1</b>")
  P3 --> S2("Storage")
  end
{{< /mermaid >}}
<figcaption>Parser Flow: Three different clients are sending data to Humio. They each have a parser assigned that will be used during ingestion. E.g. <b>Web Application</b> is using a custom parser while <b>Filebeat</b> is using the build-in <em>accesslog</em> parser.</figcaption>
</figure>

## Choosing a parser

When sending data to Humio you have to specify:

1. Which repository to storage the data in
1. Which parser to use for ingesting the data

If you are using one of the [HTTP APIs]({{< ref "api/_index.md" >}}) the repository
name is part of the URL you send data to, or
in case of the ElasticSearch Bulk API the repository name is included in the message body.

### Specifying the parser

To specify the parser you either:

- Set the special `#type` field in the message body to be the name of the parser to use, or
- [Assign a specific parser to the Ingest API Token]({{< ref "assigning-parsers-to-ingest-tokens.md" >}})
used to authenticate the client.

Assigning a parser to the API Token is the recommended approach since it allows
you to change parser in Humio without reconfiguring your clients.  

## Build-in parsers {#built-in}

Humio supports a range of common log formats out of the box.
They include formats such as `json` and `accesslog`, and are suitable when starting out
with Humio. Once you get acquainted with how parsers work you will likely want to
create your own custom parsers.

You can see the [full list of built-in parsers here]({{< ref "parsers/built-in-parsers/_index.md" >}}).

## Creating a Custom Parser {#custom}

Writing a custom parser allows you to have full control of what is stored and
during ingest, which fields are extracted from the input and which [datasource]({{< ref "datasources.md" >}})
events are saved to.

Creating your own parser involves writing a script in the Humio Language (the same
you use for searching). Here is a guide for [creating a custom parser]({{< ref "creating-a-parser.md" >}}).
