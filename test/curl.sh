ontology="@biopax.owl"
input="@input.json"
response=$0.json

curl \
	-F ontology=$ontology \
	-F input=$input \
	-H "charset=utf-8" \
	-o $response \
	http://localhost:9081/raki