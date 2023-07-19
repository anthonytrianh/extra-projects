using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Asteroid : MonoBehaviour
{
    public Transform singularity;

    public float pullForce = 1;
    Rigidbody rb;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    private void FixedUpdate()
    {
        Vector3 dir = singularity.position - transform.position;    

        rb.AddForce(dir.normalized * pullForce * Time.fixedDeltaTime);
    }
}
