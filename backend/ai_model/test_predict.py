import traceback
import sys

from yolo_service import PricePredictionRequest, predict_price

try:
    req = PricePredictionRequest(
        Brand='Nike', 
        Category='T-Shirt', 
        Color='Black', 
        Size='L', 
        Material='Cotton', 
        Gender='Men', 
        Season='Summer', 
        Brand_Tier='Premium'
    )
    print(predict_price(req))
except Exception as e:
    traceback.print_exc()
