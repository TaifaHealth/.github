<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
  <sch:ns prefix="f" uri="http://hl7.org/fhir"/>
  <sch:ns prefix="h" uri="http://www.w3.org/1999/xhtml"/>
  <!-- 
    This file contains just the constraints for the profile Observation
    It includes the base constraints for the resource as well.
    Because of the way that schematrons and containment work, 
    you may need to use this schematron fragment to build a, 
    single schematron that validates contained resources (if you have any) 
  -->
  <sch:pattern>
    <sch:title>f:Observation</sch:title>
    <sch:rule context="f:Observation">
      <sch:assert test="count(f:extension[@url = 'https://nshr-uat.sha.go.ke/fhir/StructureDefinition/em-clinical-guidance-message']) &lt;= 1">extension with URL = 'https://nshr-uat.sha.go.ke/fhir/StructureDefinition/em-clinical-guidance-message': maximum cardinality of 'extension' is 1</sch:assert>
      <sch:assert test="count(f:extension[@url = 'https://nshr-uat.sha.go.ke/fhir/StructureDefinition/em-qualitative-state']) &lt;= 1">extension with URL = 'https://nshr-uat.sha.go.ke/fhir/StructureDefinition/em-qualitative-state': maximum cardinality of 'extension' is 1</sch:assert>
      <sch:assert test="count(f:extension[@url = 'https://nshr-uat.sha.go.ke/fhir/StructureDefinition/em-vital-age-group']) &lt;= 1">extension with URL = 'https://nshr-uat.sha.go.ke/fhir/StructureDefinition/em-vital-age-group': maximum cardinality of 'extension' is 1</sch:assert>
      <sch:assert test="count(f:category) &gt;= 1">category: minimum cardinality of 'category' is 1</sch:assert>
      <sch:assert test="count(f:category) &lt;= 1">category: maximum cardinality of 'category' is 1</sch:assert>
      <sch:assert test="count(f:subject) &gt;= 1">subject: minimum cardinality of 'subject' is 1</sch:assert>
      <sch:assert test="count(f:encounter) &gt;= 1">encounter: minimum cardinality of 'encounter' is 1</sch:assert>
      <sch:assert test="count(f:performer) &lt;= 1">performer: maximum cardinality of 'performer' is 1</sch:assert>
      <sch:assert test="count(f:interpretation) &lt;= 1">interpretation: maximum cardinality of 'interpretation' is 1</sch:assert>
    </sch:rule>
  </sch:pattern>
</sch:schema>
