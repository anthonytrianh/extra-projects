using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HoleRotate : MonoBehaviour
{

    public float AngleAmount = 0.2f;

    [ExecuteAlways]
    void Update()
    {
        transform.localEulerAngles += new Vector3(0, AngleAmount, 0);        
    }
}
