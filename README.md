# Tarantula Classifier App

TODO: Put link to Google Play Store App here once released.

This is an application to classify a tarantula's species.
It uses a machine learning model through Google Firebase's AutoML Vision Edge.

# Disclaimer

Not all tarantula species can be identified visually. 
I am not an entomologist, just a hobby tarantula keeper who happens to be a software developer working on a personal project. 
If a human cannot visually distinguish two species, then there's a good chance a machine learning model won't be able to either. 
All classification confidence values should be taken with a grain of salt. 

That being said...

# The Model

A model trained on 15 species with a minimum of 100 images each has the following performance:

![Model Performance](graphics/model_stats.jpg)
![Confusion Matrix](graphics/confusion_matrix.jpg)
![Online Classification of Majora the Curlyhair](graphics/majora_classification_online.jpg)

However, once deployed to an Android app, the model becomes completely unusable. 
Using a test image of Majora, my Brachypelma albopilosum, that was classified with ~95% confidence online (see image above), the app's compressed model gives it less than 5% confidence, while completely different looking species get a confidence of up to 50% (results differ with each attempt). 

I am awaiting a response from Google Firebase Support about how to deal with this.
