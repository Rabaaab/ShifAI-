# Skin photo model — acanthosis nigricans (screening hint)

**Author:** Zouine Aicha (Aisha)  
**Part of:** ShifAI, AI-powered early detection of insulin resistance  
**Status:** experiment, **not** used as a live feature (see *Results* and *Limits*)

> This model gives a **screening hint only, never a diagnosis**. A positive output only means
> "signs that may be worth showing to a doctor".

## Goal
Take a photo of a skin area (mainly the neck) and estimate whether it shows signs of
**acanthosis nigricans (AN)**: dark, thick, velvety patches that can go with insulin resistance.

## What was done
| Step | Details |
|---|---|
| Data | Fitzpatrick17k (v1); Fitzpatrick17k + Google SCIN smartphone photos (v2). Source and licence of every dataset in `dataset_sources.csv`. |
| Classes | AN vs. other skin conditions, balanced 1:1, negatives matched to the skin-tone distribution of the positives (and per source in v2). |
| Cleaning | Dead links skipped, near-duplicates removed with perceptual hashing, one photo per SCIN case. |
| Split | 70 / 15 / 15 (train / validation / test) **before** training, by image, no duplicates across splits, stratified by class and skin tone. |
| Model | MobileNetV3-Small pretrained on ImageNet: head only first, then fine-tuning of the last 30 layers. Augmentation (flip, rotation, zoom, brightness) and class weights. |
| Threshold | Chosen on the **validation** set (Youden J), never on the test set. |
| Evaluation | Test set used **once**: AUC with 95% bootstrap CI, sensitivity, specificity, confusion matrix, all split by Fitzpatrick skin type (I-II, III-IV, V-VI). Numbers truncated, never rounded up. |
| Explainability | Grad-CAM on 2 correct and 2 wrong test examples. |
| Export | TFLite float16, 1.94 MB, checked against Keras (max difference < 1e-6). |

## Results (test set)
| Version | Data | AN images (train/val/test) | Test n | AUC (95% CI) | Sensitivity | Specificity |
|---|---|---|---|---|---|---|
| v1 | Fitzpatrick17k | 22 (15/4/3) | 7 | 0.750 (0.250-1.000) | 0.666 (2/3) | 0.750 (3/4) |
| v2 | Fitzpatrick17k + SCIN | 24 (16/4/4) | 8 | 0.437 (0.000-1.000) | 0.750 (3/4) | 0.250 (1/4) |

Full tables, ROC and confusion matrices: `results/*/results_page.pdf`.  
Both runs are reported; neither was selected for its score.

## Limits
- **Too little data.** Fitzpatrick17k lists 92 AN images, but 70 links are dead; Google SCIN (5,033 cases) has only 2 cases with AN as the main label.
- **Unreliable test numbers.** 7-8 test images: one image more or less right moves sensitivity by 25-33 points.
- **Skin tone gap.** No AN test images on Fitzpatrick V-VI (or I-II): performance on darker skin, which matters most for a Moroccan audience, is unknown.
- **Shortcut signal.** Grad-CAM shows the model partly looking at the atlas watermark ("SFS") on some images.
- **Domain gap.** Mostly clinical atlas photos, not smartphone photos of the neck; no normal-skin class.

**Decision:** shown as an experiment, not as a live feature in the app.

## Next steps
1. Request the full Fitzpatrick17k image set from its authors (official form in the dataset README): 92 AN images, 28 on Fitzpatrick V-VI.
2. Build a consented, tone-balanced dataset of neck photos taken with phones, ideally with a dermatologist partner (Moroccan law 09-08 / CNDP).
3. Mask watermarks, add a normal-skin class, then re-run the same notebook unchanged.

## Files
```
ml/skin_model/
├── notebooks/
│   ├── v1_fitzpatrick17k_colab.ipynb        # run on Google Colab, with outputs
│   └── v2_fitzpatrick17k_scin_kaggle.ipynb  # run on Kaggle, with outputs
└── results/
    ├── v1_fitzpatrick17k/                   # results_page.pdf, Grad-CAM, model.tflite, limits.txt, ...
    └── v2_fitzpatrick17k_scin/
```
`model_info.json` describes the TFLite input/output for app integration:
input `float32 [1,224,224,3]`, RGB, raw pixels 0-255; output = probability-like score of AN-like appearance.

## How to re-run
Open a notebook in Google Colab or Kaggle (GPU, Internet on) and run all cells. The notebook downloads the data itself.

## Data sources and licences
- **Fitzpatrick17k**: Groh et al., CVPR Workshops 2021. CC BY-NC-SA 3.0 (non-commercial, share-alike). Example images in `results/` come from this dataset (Atlas Dermatologico) and keep this licence.
- **SCIN**: Google Research, Ward et al., JAMA Netw Open 2024. SCIN Data Use License (attribution required, re-identification prohibited).
