#!/bin/bash

  set -ex

  API_KEY='2f05fa9cf4a8bb16'
  INTEGRATIONS_API_URL='https://api.qualiti-dev.com'
  PROJECT_ID='3'
  CLIENT_ID='c9e634f72fbe852482d73810eb2cbaf4'
  SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
  API_URL='https://3000-qualitiai-qualitiapi-f7dl5n54uwn.ws-us47.gitpod.io/public/api'
  INTEGRATION_JWT_TOKEN='11f2d135869cb31179000d06a8b551b080e18b66d724944ddeabe89dbba7ac5a131739923f068bfb48eec4af0bf0eeddcd6199f9eb04484b5272cb4d6600ad372db1d167d71d29cc37204e7c54c49f674e1c810ff3a2ae859cded120eacd24252fdbd8d55d01a295a22fe8f84eed7886bea584806fef68a291e798611e4aea8f8b47ac33da630f4b447d750bfb99ab906862df54c2563f97d6a2651af6991471f37fe60e43efea9fdb80a1438dcdc2897dc00995a3732217fabaa8542142bd21f7e96ee24dad3eed12c9fbf692519dd0940619a0b84d199ba53fff70288a125267210b8d9932486501a4c29f7ac86fee1865293afd50e24f32fb0b8afd2c35e283f830f0603683c39a303f6a80084776|dff38bff3f88a5a510b20fd6c3bd7a45|4bf124864218cffc1b043fd87421ddbb'

  apt-get update -y
  apt-get install -y jq

  #Trigger test run
  TEST_RUN_ID="$( \
    curl -X POST -G ${INTEGRATIONS_API_URL}/integrations/codeship/${PROJECT_ID}/events \
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
  TOTAL_ITERATION=200
  I=1
  while : ; do
     RESULT="$( \
     curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
     -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
     -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].finished')"
    if [ "$RESULT" != null ]; then
      break;
    if [ "$I" -ge "$TOTAL_ITERATION" ]; then
      echo "Exit qualiti execution for taking too long time.";
      exit 1;
    fi
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
  if [ "$TEST_RUN_RESULT" = "Passed" ]; then
    exit 0;
  fi
  exit 1;
  
