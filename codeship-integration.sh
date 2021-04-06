#!/bin/bash
 
set -ex
 
PROJECT_ID='333'
API_KEY='0gdAzMkEvcVSoH6adocE2GsGe6htk6lazoHZhE54'
CLIENT_ID='c52d9c3c5c38b2a754e4c7ed118c62e2'
SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
API_URL='https://7iggpnqgq9.execute-api.us-east-2.amazonaws.com/udbodh/api'
INTEGRATION_JWT_TOKEN='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcm9qZWN0X2lkIjozMzMsImFwaV9rZXlfaWQiOjMyMzcsIm5hbWUiOiIiLCJkZXNjcmlwdGlvbiI6IiIsImljb24iOiIiLCJpbnRlZ3JhdGlvbl9uYW1lIjoiQml0YnVja2V0Iiwib3B0aW9ucyI6e30sImlhdCI6MTYxNzY4MTQ2MX0.FkM0WoBaVmmxVyHY6_ZgVD_vF5cDxppvnhKXFCdkDoM'
INTEGRATIONS_API_URL='http://4ae802c42a40.ngrok.io'
 
apt-get update -y
apt-get install -y jq
 
#Trigger test run
TEST_RUN_ID="$( \
  curl -X POST -G ${INTEGRATIONS_API_URL}/api/integrations/bitbucket/${PROJECT_ID}/events \
    -d 'token='$INTEGRATION_JWT_TOKEN''\
    -d 'triggerType=Deploy'\
  | jq -r '.test_run_id')"
 
AUTHORIZATION_TOKEN="$( \
  curl -X POST -G ${API_URL}/auth/token \
  -H 'x-api-key: '${API_KEY}'' \
  -H 'client_id: '${CLIENT_ID}'' \
  -H 'scopes: '${SCOPES}'' \
  | jq -r '.token')"
 
# Wait until the test run has finished
while : ; do
   RESULT="$( \
   curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
   -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
   -H 'x-api-key: '${API_KEY}'' \
  | jq -r '.[0].finished')"
  if [ "$RESULT" != null ]; then
    break;
  fi
    sleep 15;
done
 
# # Once finished, verify the test result is created and that its passed
TEST_RUN_RESULT="$( \
  curl -X GET ${API_URL}/test-results?test_run_id=${TEST_RUN_ID}\&project_id=${PROJECT_ID} \
    -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
    -H 'x-api-key: '${API_KEY}'' \
  | jq -r '.[0].status' \
)"
echo "Qualiti E2E Tests ${TEST_RUN_RESULT}"
