
# coding: utf-8

# In[2]:


import pandas as pd


# We imported the General Election results from the [DC Board of Elections](https://electionresults.dcboe.org/election_results/2012-General-Election) for the years 2012-2018, inclusive. Earlier historic election results are available, but would require dealing with ANC boundary changes.

# In[3]:


dc_2012 = pd.read_csv('../raw_data/November_6_2012_General_and_Special_Election_Certified_Results.csv')
dc_2014 = pd.read_csv('../raw_data/November_4_2014_General_Election_Certified_Results.csv')
dc_2016 = pd.read_csv('../raw_data/November_4_2014_General_Election_Certified_Results.csv')
dc_2018 = pd.read_csv('../raw_data/November_6_2018_General_Election_Certified_Results.csv')


# 2012-2016 had consistent headers. 2018 was renamed to be consistent.

# In[4]:


# rename the 2018 dataframe headers
dc_2018 = dc_2018.rename(columns = {'ElectionDate':'ELECTION_DATE',  'ElectionName': 'ELECTION_NAME', 'ContestNumber': 'CONTEST_ID',
                'ContestName': 'CONTEST_NAME', 'PrecinctNumber': 'PRECINCT_NUMBER', 'WardNumber': 'WARD',
                'Candidate': 'CANDIDATE', 'Party': 'PARTY', 'Votes': 'VOTES'}, index=str)


# In[5]:


dc_2012.dtypes


# In[6]:


# initial merge
dc_2012_2016 = pd.concat([dc_2012, dc_2014, dc_2016], sort=False, axis = 0)


# 2012-2016 and 2018 had slightly different formats for expressing CONTEST_NAME. We extracted the name of each ANC Single Member District from the CONTEST_NAME column and created a new column for the SMD.

# In[7]:


# add the appropriate SMD column for the various years
dc_2012_2016['SMD'] = dc_2012_2016.CONTEST_NAME.str[-4:]
dc_2018['SMD'] = dc_2018.CONTEST_NAME.str[6:10]


# In[8]:


dc_2012_2018 = pd.concat([dc_2012_2016, dc_2018], sort=False, axis = 0)


# In[9]:


# filter for just the results that include the name "ANC" or "ADVISORY NEIGHBORHOOD COMMISSIONER"
anc_only =  dc_2012_2018[(dc_2012_2018['CONTEST_NAME'].str.contains("ANC")) | (dc_2012_2018['CONTEST_NAME'].str.contains("ADVISORY NEIGHBORHOOD COMMISSIONER")) ]


# In[11]:


anc_only.ELECTION_DATE = anc_only.ELECTION_DATE.apply(pd.to_datetime)


# In[12]:


anc_only.shape


# In[13]:


anc_only.dtypes


# In[14]:


anc_only.groupby(['ELECTION_DATE', 'SMD', 'CANDIDATE']).VOTES.sum()


# In[15]:


# verify ward 8 against current officeholders
anc_only[anc_only.WARD==8].groupby(['ELECTION_DATE', 'SMD', 'CANDIDATE']).VOTES.sum()


# In[16]:


#with pd.option_context("max.rows", 300):
    #print(dc_2012_2018.CONTEST_NAME.value_counts())


# In[17]:


df = anc_only.groupby(['ELECTION_DATE', 'SMD', 'CANDIDATE']).VOTES.sum()


# In[18]:


df = df.reset_index()


# In[19]:


grouper = df.groupby(['ELECTION_DATE', 'SMD'])
# Number of candidates in each SMD ANC race. Usually if there are 2 "candidates" in the race, the winner was unopposed as the other "candidate"
# were the pile of write-ins.
grouper.CANDIDATE.count()


# In[20]:


# there are 296 SMDs as per https://thedcline.org/2018/08/14/districts-296-anc-races-draw-as-many-as-five-candidates-but-two-thirds-are-uncontested/
df.SMD.value_counts()


# In[21]:


df


# In[22]:


df['WARD'] = df.SMD.str[:1]


# In[24]:


df.tail()


# In[25]:


# save progress
df.to_csv('../cleaned_data/anc_electoral_history_2012_2018.csv')

