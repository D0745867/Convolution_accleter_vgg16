# Convolution_accleter_vgg16
卷積神經網路硬體加速器實作

## 內容說明
使用Verilog實現一個DNN硬體加速器，以FSM為基底，重復使用運算單元對圖片進行卷積運算以及RELU計算，其中使用了LineBuffer的硬體架構處理輸入之圖片，在實作的過程中考慮input, output, channel數目來設計最有效率的硬體加速電路
