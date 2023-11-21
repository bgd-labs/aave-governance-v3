//
// Specification for Openzeppelin AddressSet used by GovernanceCore._votersRepresented 

/* ND - we have a much better spec for this: 
 https://github.com/Certora/Examples/blob/master/CVLByExample/QuantifierExamples/EnumerableSet/certora/spec/set.spec
lets switch to that on new projects and then the requireinvaraint is much easier 
*/
// 

methods{
    function getRepresentedVotersSize(address,uint256) external returns (uint256) envfree;
 
}



/**
* Set map entries point to valid array entries
* @notice an essential condition of the set, should hold for evert Set implementation 
* @return true if all map entries points to valid indexes of the array.
*/
definition MAP_POINTS_INSIDE_ARRAY() returns bool = forall address rep. forall uint256 chain. forall bytes32 a. mirrorMap[rep][chain][a] <= mirrorArrayLen[rep][chain];
/**
* Set map is the inverse function of set array. 
* @notice an essential condition of the set, should hold for evert Set implementation 
* @notice this condition depends on the other set conditions, but the other conditions do not depend on this condition.
*          If this condition is omitted the rest of the conditions still hold, but the other conditions are required to prove this condition.
* @return true if for every valid index of the array it holds that map(array(index)) == index + 1.
*/
definition MAP_IS_INVERSE_OF_ARRAY() returns bool = forall address rep. forall uint256 chain. forall uint256 i. (i < mirrorArrayLen[rep][chain]) => to_mathint(mirrorMap[rep][chain][(mirrorArray[rep][chain][i])]) == i + 1;

/**
* Set array is the inverse function of set map
* @notice an essential condition of the set, should hold for evert Set implementation 
* @return true if for every non-zero bytes32 value stored in in the set map it holds that array(map(value) - 1) == value
*/
definition ARRAY_IS_INVERSE_OF_MAP() returns bool = forall address rep. forall uint256 chain. forall bytes32 a. forall uint256 b. 
            (to_mathint(b) == mirrorMap[rep][chain][a]-1) => ((mirrorMap[rep][chain][a] != 0) => (mirrorArray[rep][chain][b] == a));




/**
* load array length
* @notice a dummy condition that forces load of array length, using it forces initialization of  mirrorArrayLen
* @return always true
*/
definition CVL_LOAD_ARRAY_LENGTH(address representative, uint256 chainId) returns bool
             = (getRepresentedVotersSize(representative, chainId) == getRepresentedVotersSize(representative, chainId));

/**
* Set-general condition, encapsulating all conditions of Set 
* @notice this condition recaps the general characteristics of Set. It should hold for all set implementations i.e. AddressSet, UintSet, Bytes32Set
* @return conjunction of the Set three essential properties.
*/
definition SET_INVARIANT(address representative, uint256 chainId) returns bool = 
        MAP_POINTS_INSIDE_ARRAY() && MAP_IS_INVERSE_OF_ARRAY() && ARRAY_IS_INVERSE_OF_MAP() &&  CVL_LOAD_ARRAY_LENGTH(representative, chainId); 

/**
 * Size of stored value does not exceed the size of an address type.
 * @notice must be used for AddressSet, must not be used for Bytes32Set, UintSet
 * @return true if all array entries are less than 160 bits.
 **/
definition VALUE_IN_BOUNDS_OF_TYPE_ADDRESS() returns bool = (forall address rep. forall uint256 chain. forall uint256 i. (mirrorArray[rep][chain][i]) & to_bytes32(max_uint160) == mirrorArray[rep][chain][i]);

/**
 * A complete invariant condition for AddressSet
 * @notice invariant addressSetInvariant proves that this condition holds
 * @return conjunction of the Set-general and AddressSet-specific conditions
 **/
definition ADDRESS_SET_INVARIANT(address representative, uint256 chainId) returns bool =
             SET_INVARIANT(representative, chainId) && VALUE_IN_BOUNDS_OF_TYPE_ADDRESS();

/**
 * A complete invariant condition for UintSet, Bytes32Set
 * @notice for UintSet and Bytes2St no type-specific condition is required because the type size is the same as the native type (bytes32) size
 * @return the Set-general condition
 **/
definition UINT_SET_INVARIANT(address representative, uint256 chainId) returns bool = SET_INVARIANT(representative, chainId);

/**
 * Out of bound array entries are zero
 * @notice A non-essential  condition. This condition can be proven as an invariant, but it is not necessary for proving the Set correctness.
 * @return true if all entries beyond array length are zero
 **/
definition ARRAY_OUT_OF_BOUND_ZERO() returns bool = forall address rep. forall uint256 chain. forall uint256 i. (i >= mirrorArrayLen[rep][chain]) => (mirrorArray[rep][chain][i] == to_bytes32(0));

// For CVL use

/**
 * ghost mirror map, mimics Set map
 **/
ghost mapping(address => mapping(uint256 => mapping(bytes32 => uint256))) mirrorMap{ 
    init_state axiom forall address rep. forall uint256 chain. forall bytes32 a. mirrorMap[rep][chain][a] == 0;
    
}

/**
 * ghost mirror array, mimics Set array
 **/
ghost mapping(address => mapping(uint256 => mapping(uint256 => bytes32))) mirrorArray{
    init_state axiom forall address rep. forall uint256 chain. forall uint256 i. mirrorArray[rep][chain][i] == to_bytes32(0);
}

/**
 * ghost mirror array length, mimics Set array length
 * @notice ghost includes an assumption about the array length. 
  * If the assumption were not written in the ghost function it should be written in every rule and invariant.
  * The assumption holds: breaking the assumptions would violate the invariant condition 'map(array(index)) == index + 1'. Set map uses 0 as a sentinel value, so the array cannot contain MAX_INT different values.  
  * The assumption is necessary: if a value is added when length==MAX_INT then length overflows and becomes zero.
 **/
ghost mapping(address => mapping(uint256 => uint256)) mirrorArrayLen{
    init_state axiom forall address rep. forall uint256 chain. mirrorArrayLen[rep][chain] == 0;
    axiom forall address rep. forall uint256 chain. mirrorArrayLen[rep][chain] < max_uint256;
}


/**
 * hook for Set array stores
 * @dev user of this spec must replace _list with the instance name of the Set.
 **/
hook Sstore _votersRepresented [KEY address rep] [KEY uint256 chain] .(offset 0)[INDEX uint256 index] bytes32 newValue (bytes32 oldValue) STORAGE {
    mirrorArray[rep][chain][index] = newValue;
}

/**
 * hook for Set array loads
 * @dev user of this spec must replace _list with the instance name of the Set.
 **/
hook Sload bytes32 value _votersRepresented [KEY address rep] [KEY uint256 chain] .(offset 0)[INDEX uint256 index] STORAGE {
    require(mirrorArray[rep][chain][index] == value);
}
/**
 * hook for Set map stores
 * @dev user of this spec must replace _list with the instance name of the Set.
 **/
hook Sstore _votersRepresented [KEY address rep] [KEY uint256 chain] .(offset 32)[KEY bytes32 key] uint256 newIndex (uint256 oldIndex) STORAGE {
      mirrorMap[rep][chain][key] = newIndex;
}

/**
 * hook for Set map loads
 * @dev user of this spec must replace _list with the instance name of the Set.
 **/
hook Sload uint256 index _votersRepresented [KEY address rep] [KEY uint256 chain] .(offset 32)[KEY bytes32 key] STORAGE {
    require(mirrorMap[rep][chain][key] == index);
}

/**
 * hook for Set array length stores
 * @dev user of this spec must replace _list with the instance name of the Set.
 **/
hook Sstore _votersRepresented  [KEY address rep] [KEY uint256 chain] .(offset 0).(offset 0) uint256 newLen (uint256 oldLen) STORAGE {
        mirrorArrayLen[rep][chain] = newLen;
}

/**
 * hook for Set array length load
 * @dev user of this spec must replace _votersRepresented with the instance name of the Set.
 **/
hook Sload uint256 len _votersRepresented  [KEY address rep] [KEY uint256 chain] .(offset 0).(offset 0) STORAGE {
    require mirrorArrayLen[rep][chain] == len;
}

/**
 * main Set general invariant
 **/
invariant setInvariant(env e1, address representative, uint256 chainId)
    SET_INVARIANT(representative, chainId)
    {
        preserved with (env e2)
        {require e1.msg.sender == e2.msg.sender;}
    }


/**
 * main AddressSet invariant
 * @dev user of the spec should add 'requireInvariant addressSetInvariant();' to every rule and invariant that refer to a contract that instantiates AddressSet  
 **/
invariant addressSetInvariant(address representative, uint256 chainId)
    ADDRESS_SET_INVARIANT(representative, chainId);


//Out of bound array entries are zero
invariant array_out_of_bound_entries_are_zero(address representative, uint256 chainId)
    ARRAY_OUT_OF_BOUND_ZERO()
    {
        preserved{
            requireInvariant addressSetInvariant(representative, chainId);
        }
    }


// Set size can be 2 ^ 160 - 1 
rule set_size_eq_max_uint160_witness(method` f)
filtered {f -> f.selector == sig:GovernanceHarness.updateRepresentativesForChain(IGovernanceCore.RepresentativeInput[]).selector}
{
   address representative;
    uint256 chainId;
    requireInvariant addressSetInvariant(representative, chainId);
    require ARRAY_OUT_OF_BOUND_ZERO();
    
    require getRepresentedVotersSize(representative, chainId) < max_uint160;
    env e; calldataarg args;
    f(e, args);
    satisfy getRepresentedVotersSize(representative, chainId) == max_uint160 ;
}

