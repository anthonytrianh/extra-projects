using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraClipPlanes : MonoBehaviour
{
    public Camera cam;
    public Vector3[] points;
    public Vector3[] frustumCorners = new Vector3[4];
    private Vector4[] projectedPoints;

    public Vector3[] CenterPoints;

    public LayerMask WaterMask;
    Vector3 WaterPoint;

    public void Start()
    {
        cam = GetComponent<Camera>();
    }

    private void Update()
    {
        var camera = GetComponent<Camera>();

        points = new Vector3[4];
        frustumCorners = new Vector3[4];

        camera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), camera.nearClipPlane, Camera.MonoOrStereoscopicEye.Mono, frustumCorners);
        for (int i = 0; i < 4; i++)
        {
            var worldSpaceCorner = camera.transform.TransformVector(frustumCorners[i]);
            points[i] = camera.transform.TransformVector(frustumCorners[i]);
            Debug.DrawRay(camera.transform.position, worldSpaceCorner, Color.blue);
        }


        // Min max
        Vector3 min = new Vector3(float.MaxValue, float.MaxValue, float.MaxValue);
        Vector3 max = new Vector3(float.MinValue, float.MinValue, float.MinValue);
        for (int i = 0; i < 4; i++)
        {
            min.x = (min.x > points[i].x) ? points[i].x : min.x;
            min.y = (min.y > points[i].y) ? points[i].y : min.y;
            min.z = (min.z > points[i].z) ? points[i].z : min.z;
            max.x = (max.x < points[i].x) ? points[i].x : max.x;
            max.y = (max.y < points[i].y) ? points[i].y : max.y;
            max.z = (max.z < points[i].z) ? points[i].z : max.z;
        }

        // Center points
        CenterPoints = new Vector3[2];
        CenterPoints[0] = new Vector3(0, min.y, min.z) + camera.transform.position;
        CenterPoints[1] = new Vector3(0, max.y, max.z) + camera.transform.position;

        // Collision
        RaycastHit Hit;
        Physics.Linecast(CenterPoints[1], CenterPoints[0], out Hit, WaterMask);
        WaterPoint = Hit.point;
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.white;
        if (CenterPoints.Length > 0)
        {
            Gizmos.DrawSphere(CenterPoints[0], 0.05f);
            Gizmos.DrawSphere(CenterPoints[1], 0.05f);
        }
    
        Gizmos.color = Color.green;
        Gizmos.DrawSphere(WaterPoint, 0.05f);
    }
}
