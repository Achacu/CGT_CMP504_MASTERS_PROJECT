#include "stdafx.h"
#include "EllipsoidPrimitiveFileReader.h"

inline Vector3 StrToVector3(string s)
{
	stringstream ss(s);
	string coord;
	float coords[3]{};
	for (int i = 0; i < 3; i++)
	{
		getline(ss, coord, ',');
		coords[i] = atof(coord.c_str());		
	}
	return Vector3(coords);
}
inline Vector4 StrToVector4(string s)
{
	stringstream ss(s);
	string coord;
	float coords[4]{};
	for (int i = 0; i < 4; i++)
	{
		getline(ss, coord, ',');
		coords[i] = atof(coord.c_str());
	}
	return Vector4(coords);
}
void EllipsoidPrimitiveFileReader::ReadEllipsoidDataFromFile(string filePath)
{
	ifstream myReadFile(filePath);

	string line;
	while (getline(myReadFile, line))
	{
		//string id = line.substr(0, line.find_first_of(':'));
		//string transformStr = line.substr(id.size() + 1);
		if (line[0] == '#') continue; //ignore comments
		ReadEllipsoidLine(line);
	}
	myReadFile.close();
}
void EllipsoidPrimitiveFileReader::ReadEllipsoidLine(string lineStr)
{
	stringstream ss(lineStr);
	string centerStr, radiiStr, quatStr, albedoStr, sigmaStr;

	getline(ss, centerStr, ']');
	Vector3 center = StrToVector3(centerStr.substr(1));
	getline(ss, radiiStr, ']');
	Vector3 radii = StrToVector3(radiiStr.substr(2));
	getline(ss, quatStr, ']');
	Vector4 quat = StrToVector4(quatStr.substr(2)); //change to vector4
	getline(ss, albedoStr, ']');
	Vector3 albedo = StrToVector3(albedoStr.substr(2));
	getline(ss, sigmaStr, '\n');
	float sigma = atof(sigmaStr.substr(1).c_str()); //TODO
	AddEllipsoid(center, radii, quat, 3.0f);
	AddKernelPrimitive(albedo, sigma);
}

void EllipsoidPrimitiveFileReader::AddEllipsoid(Vector3 center, Vector3 radii, Vector4 quat, float extent)
{
	auto el = Ellipsoid();
	el.center = center;
	el.radii = radii;
	el.quat = quat;
	//TODO rot from quat
	el.extent = extent;

	ellipsoids.push_back(el);
}

void EllipsoidPrimitiveFileReader::AddKernelPrimitive(Vector3 albedo, float sigma)
{
	auto ker = KernelPrimitive();
	ker.albedo = albedo;
	ker.sigma = sigma;
	kernels.push_back(ker);
}
