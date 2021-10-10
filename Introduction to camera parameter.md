### 这里介绍相机标定的参数及其涵义。

先介绍两个工具：
1. T-Calibration
2. Matlab Camera Calibrator

1. T-Calibration:

1.1 介绍：
  1) T-Calibration是Lund University开发的一款免费软件。它包含两种模式：使用谷歌地图的数据作为世界坐标的来源；使用用户实地
     测量的世界坐标作为测量的来源。
![Image text](https://github.com/q7224756/VideoAnalysis_And_DataFusion/blob/master/Abbildungen/image.png)

dx:      1
dy:      1
Cx:      926.94478716582
Cy:      522.135559983725
Sx:      1
 f:      1096.29252391656
 k:      3.02229087812489E-08
Tx:      -5.60497866710708
Ty:      0.992827592907087
Tz:      25.0397938343522
r1:      0.647006255546446
r2:      0.762069313348746
r3:      -0.025164795567174
r4:      -0.498123503975734
r5:      0.447439691819872
r6:      0.742745378289946
r7:      0.577283188799661
r8:      -0.468025729887053
r9:      0.66910091622489


2. Matlab Camera Calibrator

2.1 介绍
  1) Matlab Camera Calibrator是Matlab Computer Version Toolbox的一个应用。它能够标定出相机的内参、外参和畸变系数，可以用于去除透镜畸变。
  2) Matlab Camera Calibrator使用多张待标定相机拍摄的标定板图片。软件能够识别标定板图片中的标定点，并提取它的坐标值。通过提供标定板的实际几何尺寸，
     软件可以获知像素坐标和世界坐标的映射关系。标定算法先计算出内参和外参，假设无透镜畸变，然后使用Levenberg-Marquardt最小二乘优化算法求解透镜畸
     变系数和准确的内外参。


