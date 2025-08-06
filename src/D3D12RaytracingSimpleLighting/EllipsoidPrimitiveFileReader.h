#pragma once
#include <string>
#include <iostream>
#include <fstream>
#include <SimpleMath.h>
using namespace DirectX;
using namespace DirectX::SimpleMath;
using namespace std;

class EllipsoidPrimitiveFileReader
{
public:

    struct Ellipsoid
    {
        Vector3 center;
        Vector3 radii; //radii <= 1 
        //Quaternion quat;
        Matrix rot;
        float extent = 3.0f; //scale factor
    };
    struct KernelPrimitive
    {
        float sigma; //cross section
        Vector3 albedo; //computed from pdf???
    };

    void ReadEllipsoidDataFromFile(string filePath);
private:
    void ReadEllipsoidLine(string lineStr);

    void AddEllipsoid(Vector3 center, Vector3 radii, Quaternion quat, float extent);

    void AddKernelPrimitive(Vector3 albedo, float sigma);
    vector<Ellipsoid> ellipsoids;
    vector<KernelPrimitive> kernels;
};

