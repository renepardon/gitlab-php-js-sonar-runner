# Usage

## .gitlab-ci.yml

This is an example Gitlab CI pipeline configuration for a laravel application which makes use of PHP and Javascript as 
well as Sonarqube.

    image: renepardon/gitlab-php-js-sonar-runner:latest
    
    cache:
      paths:
      - vendor/
      - node_modules/
    
    stages:
    - build
    - test
    - sonar
    - release
    
    variables:
      REGISTRY: repository.<YOURDOMAIN>.com:4567
      NIGHTLY_IMAGE: $REGISTRY/<YOURCOMPANY>/<YOURPROJECT>:$CI_BUILD_REF
      LATEST_IMAGE: $REGISTRY/<YOURCOMPANY>/<YOURPROJECT>:latest
    
    build:
      stage: build
      before_script:
      - docker info
      - cp .env.example .env
      - sed -i "s/CACHE_DRIVER=.*/CACHE_DRIVER=array/" .env
      - sed -i "s/SESSION_DRIVER=.*/SESSION_DRIVER=array/" .env
      - php composer.phar install
      - php artisan key:generate
      - npm install
      - npm run prod
      script:
      - docker login -u jenkins -p <YOURLOGINTOKEN> $REGISTRY
      - docker build -t $NIGHTLY_IMAGE -f ./Dockerfile --pull .
      - docker push $NIGHTLY_IMAGE
    
    test:7.3:
      stage: test
      before_script:
      - cp .env.example .env
      - sed -i "s/CACHE_DRIVER=.*/CACHE_DRIVER=array/" .env
      - sed -i "s/SESSION_DRIVER=.*/SESSION_DRIVER=array/" .env
      - php composer.phar install
      - php artisan key:generate
      script:
      - ./vendor/bin/phpunit
      artifacts:
        paths:
        - ./build/reports/coverage/
        - ./build/reports/unitreport.xml
    
    test:javascript:
      stage: test
      image: node:8-alpine
      before_script:
      - npm install
      - npm run prod
      script:
      - npm run test
    
    sonar:
      stage: sonar
      image: ciricihq/gitlab-sonar-scanner
      dependencies:
      - test:7.3
      variables:
        SONAR_URL: https://sonar.<YOURDOMAIN>.com
        SONAR_ANALYSIS_MODE: publish
      script:
      - gitlab-sonar-scanner
    
    release:
      stage: release
      image: gitlab/dind
      script:
      - docker login -u jenkins -p <YOURLOGINTOKEN> $REGISTRY
      - docker pull $NIGHTLY_IMAGE
      - docker tag $NIGHTLY_IMAGE $LATEST_IMAGE
      - docker push $LATEST_IMAGE
      only:
      - master
