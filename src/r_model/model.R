suppressPackageStartupMessages({
  library(tidyverse)
  library(tidymodels)
})

main <- function() {
  # ---- Load datasets ----
  train <- readr::read_csv("src/data/train.csv", show_col_types = FALSE)
  test  <- readr::read_csv("src/data/test.csv",  show_col_types = FALSE)
  sub   <- readr::read_csv("src/data/gender_submission.csv", show_col_types = FALSE)
  cat(sprintf("[INFO] train: %d x %d | test: %d x %d | submission: %d x %d\n",
              nrow(train), ncol(train), nrow(test), ncol(test), nrow(sub), ncol(sub)))
  
  # ---- Feature engineering ----
  train <- train %>%
    mutate(
      FamilySize = SibSp + Parch + 1L,
      IsMale     = as.integer(Sex == "male")
    )
  
  test <- test %>%
    mutate(
      FamilySize = SibSp + Parch + 1L,
      IsMale     = as.integer(Sex == "male")
    )
  cat("[FE] Created features: FamilySize, IsMale\n")
  
  # ---- Prepare data for modeling ----
  features <- c("Pclass", "Fare", "Age", "FamilySize", "IsMale")
  cat(sprintf("[FEATURES] Using features: %s\n", paste(features, collapse = ", ")))
  
  # Ensure target is a factor with levels "0","1" for classification metrics
  train <- train %>%
    mutate(Survived = factor(Survived, levels = c(0, 1), labels = c("0", "1")))
  
  # Coerce categoricals to factor for recipe steps
  train <- train %>%
    mutate(Pclass = factor(Pclass), IsMale = factor(IsMale))
  test  <- test  %>%
    mutate(Pclass = factor(Pclass), IsMale = factor(IsMale))
  
  # ---- Preprocessing recipe (impute, scale, one-hot) ----
  rec <- recipe(Survived ~ Pclass + Fare + Age + FamilySize + IsMale, data = train) %>%
    # Impute numeric with median
    step_impute_median(Fare, Age, FamilySize) %>%
    # Impute categorical with mode
    step_impute_mode(Pclass, IsMale) %>%
    # One-hot encode categoricals
    step_dummy(Pclass, IsMale, one_hot = TRUE) %>%
    # Standardize numeric features
    step_normalize(Fare, Age, FamilySize)
  
  # ---- Model: Logistic Regression ----
  clf <- logistic_reg(mode = "classification") %>%
    set_engine("glm")  # base R glm (binomial)
  
  wf <- workflow() %>%
    add_model(clf) %>%
    add_recipe(rec)
  
  cat("[TRAIN] Fitting logistic regression model...\n")
  fit <- fit(wf, data = train)
  
  # ---- Training accuracy ----
  train_preds <- predict(fit, new_data = train, type = "class") %>%
    bind_cols(predict(fit, new_data = train, type = "prob")) %>%
    bind_cols(train %>% select(Survived))
  
  train_acc <- yardstick::accuracy(train_preds, truth = Survived, estimate = .pred_class) %>%
    dplyr::pull(.estimate)
  
  cat(sprintf("[METRIC] TRAIN accuracy: %.4f\n", train_acc))
  
  # ---- Test predictions ----
  cat("[PREDICT] Predicting on test set...\n")
  test_classes <- predict(fit, new_data = test, type = "class") %>%
    pull(.pred_class)
  
  # Show first 20 predictions as integers 0/1 (to match your Python print)
  first20 <- head(test_classes, 20)
  first20_num <- as.integer(as.character(first20))
  cat("[OUTPUT] First 20 predictions: ",
      paste(first20_num, collapse = ", "), "\n", sep = "")
  
  # ---- Merge predictions with 'gender_submission' and score ----
  merged <- tibble(PassengerId = test$PassengerId, Predicted = test_classes) %>%
    mutate(Predicted = factor(Predicted, levels = c("0", "1"))) %>%
    left_join(sub %>%
                mutate(Survived = factor(Survived, levels = c(0, 1), labels = c("0", "1"))),
              by = "PassengerId") %>%
    drop_na(Survived)
  
  if (nrow(merged) > 0) {
    test_acc <- yardstick::accuracy(merged, truth = Survived, estimate = Predicted) %>%
      dplyr::pull(.estimate)
    cat(sprintf("[METRIC] TEST accuracy (vs gender_submission): %.4f\n", test_acc))
  } else {
    cat("[WARN] No overlapping PassengerId rows between test predictions and gender_submission.\n")
  }
}

if (sys.nframe() == 0) {
  main()
}

