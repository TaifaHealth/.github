<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
  <sch:ns prefix="f" uri="http://hl7.org/fhir"/>
  <sch:ns prefix="h" uri="http://www.w3.org/1999/xhtml"/>
  <!-- 
    This file contains just the constraints for the profile Location
    It includes the base constraints for the resource as well.
    Because of the way that schematrons and containment work, 
    you may need to use this schematron fragment to build a, 
    single schematron that validates contained resources (if you have any) 
  -->
  <sch:pattern>
    <sch:title>f:Location</sch:title>
    <sch:rule context="f:Location">
      <sch:assert test="count(f:extension[@url = 'https://nshr-uat.sha.go.ke/fhir/StructureDefinition/em-last-location-updated-at']) &lt;= 1">extension with URL = 'https://nshr-uat.sha.go.ke/fhir/StructureDefinition/em-last-location-updated-at': maximum cardinality of 'extension' is 1</sch:assert>
      <sch:assert test="count(f:extension[@url = 'https://nshr-uat.sha.go.ke/fhir/StructureDefinition/em-unit-response-status']) &lt;= 1">extension with URL = 'https://nshr-uat.sha.go.ke/fhir/StructureDefinition/em-unit-response-status': maximum cardinality of 'extension' is 1</sch:assert>
      <sch:assert test="count(f:status) &gt;= 1">status: minimum cardinality of 'status' is 1</sch:assert>
      <sch:assert test="count(f:mode) &gt;= 1">mode: minimum cardinality of 'mode' is 1</sch:assert>
    </sch:rule>
  </sch:pattern>
</sch:schema>
