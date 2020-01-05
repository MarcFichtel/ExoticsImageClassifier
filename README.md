# Tarantula Classifier App

TODO: Put link to Google Play Store App here once released.

This is an application to identify a tarantula's species.
It uses a machine learning model through Google Firebase's AutoML Vision Edge.

# Disclaimer

Not all tarantula species can be identified visually. 
I am not an entomologist, just a hobby tarantula keeper who happens to be a software developer working on a personal project. 
If a human cannot visually distinguish two species, then there's a good chance a machine learning model won't be able to either. 
Thus, all classification confidence values should be taken with a grain of salt. 

That being said...

# The Model

Model min100_20191228 was trained on 21 species using a total of 2587 images and has the following performance:

![Model Performance](graphics/model_stats.jpg)
![Online Classification of Majora the Curlyhair](graphics/majora_classification_online.jpg)