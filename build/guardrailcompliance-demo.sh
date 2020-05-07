#Get the arguments
buildNumber=$1
env=$2
bwd=$(pwd)
GuardrailRequestData_xml="$(pwd)/build/Request/GuardrailsRequestData.xml"

#Check Guardrail Compliance For Current Build


#curl --header "Content-Type: text/xml;charset=UTF-8" --cacert /apps/tomcat7/tomcat-client.jks --insecure --data @$GuardrailRequestData_xml https://va33dlvpeg337.wellpoint.com:8443/prweb/PRSOAPServlet/SOAP/GuardrailsServicePkg/Services?WSDL > report_guardrail.txt
#curl --header --insecure --data @$GuardrailRequestData_xml https://18.216.109.83:8080/prweb/PRSOAPServlet/SOAP/GuardrailsServicePkg/Services?WSDL > report_guardrail.txtcd build
curl --header --insecure --data @$GuardrailRequestData_xml http://18.216.109.83:8080/prweb/PRSOAPServlet/SOAP/DemoServices/Services?WSDL > report_guardrail.txt
cat report_guardrail.txt
result=$(cat report_guardrail.txt |grep GuardrailsAPIStatus|cut -d: -f1|cut -d">" -f2|xargs)
echo "Result from Guardrail api call is: $result"
##if [[ $result != "Success" ]] ; then echo "Guardrail API call failed."; exit 3; fi


##reportpath_name="/apps/pegashared/other_apps/DevOps/Reports/PegaGuardrailsReport_COB.xls"
reportpath_name="PegaGuardrailsReport_COB.xls"
echo "Report & its path: $reportpath_name"
report_path=$(dirname $reportpath_name)
echo "report path is $report_path"
report_name=$(basename $reportpath_name)
echo "report name is $report_name"

#Copy GuardRail Result to Define artifact
##cd /apps/DevOps/Reports/
mkdir -p GuardRailReport/Build_${buildNumber}
cd GuardRailReport/Build_${buildNumber}
#rsync -avzhe ssh srccompg@va33dlvpeg337.wellpoint.com:/apps/pegashared/other_apps/DevOps/Reports/PegaGuardrailsReport_COB.xls .

##sftp srccompg@va33dlvpeg337.wellpoint.com <<EOF
##cd /apps/pegashared/other_apps/DevOps/Reports/
##get PegaGuardrailsReport_COB.xls
##exit
##EOF

#cd -
##Move report to Build_<BuildNumber> Directory
#mkdir  Build_${bamboo.buildNumber}
###Deleting the build folder for demo purpose###
rm -rf $report_path/Build_${BuildNum}
mkdir $report_path/Build_${BuildNum}

##mv $report_name  Build_${bamboo.buildNumber}
##cp $report_name  $report_path/Build_${BuildNum}

#cd $report_path
#mkdir -p GuardRailReport/$env/Build_${buildNumber}
#cd GuardRailReport/$env/Build_${buildNumber}


#Check for Guardrail compliance score
##rm -rf /apps/DevOps/Reports/Info.txt
cd $bwd
rm -rf $bwd/Reports/Info.txt
mkdir -p $bwd/Reports
#rm $bwd/Reports/Info.txt
cd ${bwd}/build
compthreshold=89
echo "<compthreshold>"$compthreshold"</compthreshold>"
echo "Bamboo current working directory is: $bwd"
compscore=$(cat report_guardrail.txt|grep -w GuardrailsComplianceScore|cut -d'>' -f2 | cut -d'<' -f1|xargs)
echo "Guardrail compliance score is  $compscore"
if [[ "$compscore" -le "$compthreshold" ]] ; then echo "The Guardrail compliance score  $compscore is lessthan the threshold $compthreshold. Build failed" >>Reports/Info.txt; exit 3; fi
#End check for Guardrail compliance score

#Check for Guardrail Unjustified high Severity Count count
cd ${bwd}/build
threshold=15
echo "<guardthreshold>"$threshold"</guardthreshold>"
echo "Bamboo current working directory is: $bwd"
highSeverity=$(cat report_guardrail.txt|grep -w GuardrailsHighSeverityCount|cut -d'>' -f2 | cut -d'<' -f1|xargs)
unjustifiedHighSeverity=$(cat report_guardrail.txt|grep -w GuardrailsUnjustifiedHighSeverityCount|cut -d'>' -f2 | cut -d'<' -f1|xargs)
echo "Total high severity count in Guardrail is $highSeverity out of which unjusyified high severity count is $unjustifiedHighSeverity"

if [[ "$unjustifiedHighSeverity" -ge "$threshold" ]] ; then echo "Unjustified high severity count $unjustifiedHighSeverity in Guardrail is greater than the threshold count  $threshold.Build failed" >>/apps/DevOps/Reports/Info.txt; exit 3; fi

cd ${bwd}/build
#Reading the guardrail scores to send mail
GCS=$(cat report_guardrail.txt|grep -w GuardrailsComplianceScore|cut -d'>' -f2 | cut -d'<' -f1|xargs)
GSC=$(cat report_guardrail.txt|grep -w GuardrailsSeverityCount|cut -d'>' -f2 | cut -d'<' -f1|xargs)
GUSC=$(cat report_guardrail.txt|grep -w GuardrailsUnjustifiedSeverityCount|cut -d'>' -f2 | cut -d'<' -f1|xargs)
GHSC=$(cat report_guardrail.txt|grep -w GuardrailsHighSeverityCount|cut -d'>' -f2 | cut -d'<' -f1|xargs)
GUHSC=$(cat report_guardrail.txt|grep -w GuardrailsUnjustifiedHighSeverityCount|cut -d'>' -f2 | cut -d'<' -f1|xargs)
GMSC=$(cat report_guardrail.txt|grep -w GuardrailsMediumSeverityCount|cut -d'>' -f2 | cut -d'<' -f1|xargs)
GUMSC=$(cat report_guardrail.txt|grep -w GuardrailsUnjustifiedMediumSeverityCount|cut -d'>' -f2 | cut -d'<' -f1|xargs)
GLSC=$(cat report_guardrail.txt|grep -w GuardrailsLowSeverityCount|cut -d'>' -f2 | cut -d'<' -f1|xargs)
GULCS=$(cat report_guardrail.txt|grep -w GuardrailsUnjustifiedLowSeverityCount|cut -d'>' -f2 | cut -d'<' -f1|xargs)

#Writing the values to the file to send mail
echo -e "******************GuardRail Scores**************************************" >>$bwd/Reports/Info.txt
echo -e "\nGuardrails Compliance Score = $GCS" >>$bwd/Reports/Info.txt
echo -e "\nGuardrails Severity Count = $GSC" >>$bwd/Reports/Info.txt
echo -e "\nGuardrails Unjustified Severity Count = $GUSC" >>$bwd/Reports/Info.txt
echo -e "\nGuardrails High Severity Count = $GHSC" >>$bwd/Reports/Info.txt
echo -e "\nGuardrails Unjustified High Severity Count = $GUHSC" >>$bwd/Reports/Info.txt
echo -e "\nGuardrails Medium Severity Count = $GMSC" >>$bwd/Reports/Info.txt
echo -e "\nGuardrails Unjustified Medium SeverityCount = $GUMSC" >>$bwd/Reports/Info.txt
echo -e "\nGuardrails LowSeverity Count = $GLSC" >>$bwd/Reports/Info.txt
echo -e "\nGuardrails Unjustified LowSeverity Count = $GULCS" >>$bwd/Reports/Info.txt

cat $bwd/Reports/Info.txt
#End of the script
