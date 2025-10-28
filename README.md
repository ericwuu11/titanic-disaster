# Welcome to the Titanic Disaster Repository 
This repository focuses on developing a model that predicts the survival of each passenger, but also instruct a user how to run through the repo that will load the data, adjust the dataset in any way, and make a prediction.

# Things you will need:
1. Docker Desktop - Make sure Docker Desktop is installed and running on your machine. This project uses Docker to provide fully reproducible environments for both R and Python models.

2. Git - Used to clone the repository to your local machine.

3. Internet connection - Required to pull the Docker base images and install dependencies during the first build.

4. Titanic dataset (https://www.kaggle.com/competitions/titanic/code). The required files: ('train.csv', 'test.csv', 'gender_submission.csv'). Place these files into the src/data/ folder after cloning the repo.

# Step 1: Clone the repository and move into the Project Directory

#### Clone the repository
git clone https://github.com/ericwuu11/titanic-disaster.git

#### Move into the Project Directory
cd titanic-disaster


# Step 2: Run Python Model
Inside the src/app folder, there is a model.py file, which contains the Python model for the Titanic Disaster.

#### Build the Python Docker Image:
docker build -t pymodel .

#### Run it on the Python Model
docker run --rm -v "${PWD}:/app" pymodel    

# Step 3: Run R Model
Note that there should be an rmodel folder inside src, and it contains three things ('Dockerfile' used for rmodel (different from the one in the root that is used for the Python model), 'install_packages.R' consists of libraries and packages that are needed to run the Dockerfile, and 'model.R' that contains the model that predicts survival.

#### Build the R Docker Image (HEADS UP - This can take anywhere from 2000-2500 seconds to complete running): 
docker build -f src/r_model/Dockerfile -t rmodel .

Note: Inside the Dockerfile for rmodel there is a line that says "FROM --platform=linux/arm64 rocker/r-base:4.5.1", make sure it matches your system (Use ARM64 on Apple Silicon; switch to linux/amd64 if you're on Intel)

#### Run it on the R Model
docker run --rm -v "${PWD}:/app" rmodel 

#### Step 4: Review Findings
In each respective folder for the models, you should see a csv file ('python_predictions.csv' and 'r_predictions.csv') that records each of predictions for each model.



