# Acanthosis nigricans model — test results

Screening hint only, not a diagnosis. Backbone: mobilenetv3. Threshold 0.251 chosen on validation.

| group              |   n |   n_AN |   n_other |   AUC | AUC_95CI    | Sensitivity   | Specificity   |   TP |   FN |   TN |   FP |
|:-------------------|----:|-------:|----------:|------:|:------------|:--------------|:--------------|-----:|-----:|-----:|-----:|
| ALL (test)         |   8 |      4 |         4 | 0.437 | 0.000-1.000 | 0.750 (3/4)   | 0.250 (1/4)   |    3 |    1 |    1 |    3 |
| Fitzpatrick III-IV |   8 |      4 |         4 | 0.437 | 0.000-1.000 | 0.750 (3/4)   | 0.250 (1/4)   |    3 |    1 |    1 |    3 |