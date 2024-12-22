using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RigidBodySway : MonoBehaviour
{
    Rigidbody rb => GetComponent<Rigidbody>();

    [SerializeField] float force = 1;
    
    // Start is called before the first frame update
    void Start()
    {
        rb.AddForce(new Vector3(Random.value, -1, Random.value) * force);
        
    }

    // Update is called once per frame
    void Update()
    {
    }
}
