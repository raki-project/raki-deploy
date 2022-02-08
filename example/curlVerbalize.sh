ontology="@KGs/Biopax/biopax.owl"
axioms="axioms.owl"
response=$0.json

jq '
   .problems
     ."((pathwayStep ⊓ (∀INTERACTION-TYPE.Thing)) ⊔ (sequenceInterval ⊓ (∀ID-VERSION.Thing)))"
   | {
      "positives": .positive_examples,
      "negatives": .negative_examples
     }' LPs/Biopax/lp.json \
  	   | curl -d@- http://localhost:9080/concept_learning >  $axioms

curl \
	-F ontology=$ontology \
	-F axioms="@"$axioms \
	-H "charset=utf-8" \
	-o $response \
	http://localhost:9081/rules
