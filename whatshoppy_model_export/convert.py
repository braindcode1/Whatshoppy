import tensorflow as tf

model = tf.keras.models.load_model(
    r"C:\Users\Ranim\Desktop\WhatShoppy-ai-local-integration\whatshoppy_model_export\whatshoppy_category_model.keras"
)

converter = tf.lite.TFLiteConverter.from_keras_model(model)

tflite_model = converter.convert()

with open(
    r"C:\Users\Ranim\Desktop\WhatShoppy-ai-local-integration\whatshoppy_model_export\whatshoppy_category_model.tflite",
    "wb"
) as f:
    f.write(tflite_model)

print("Model converted!")